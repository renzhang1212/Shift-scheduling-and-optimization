using ILOG.Concert;
using ILOG.CPLEX;
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class optimize : System.Web.UI.Page
{
    private string dateFormat = @"MM dd yyyy HH:mm";
    protected void Page_Load(object sender, EventArgs e)
    {

        string employeeJson = Request.Params["employees"];
        string shiftsJson = Request.Params["shifts"];
        string json = employeeJson + shiftsJson;
        JavaScriptSerializer serializer = new JavaScriptSerializer();
        List<Employee> employees = new List<Employee>();
        List<Shift> shifts = new List<Shift>();
        if (employeeJson == null)
        {
            Employee employee = new Employee();
            employee.description = "E1";
            employees.Add(employee);

            Shift shift = new Shift();
            shift.description = "Morning";
            shift.begin = DateTime.Now;
            shift.end = shift.begin.AddHours(8);
            shift.shiftNumber = 2;

            Shift shift2 = new Shift();
            shift2.description = "Morning";
            shift2.begin = DateTime.Now;
            shift2.end = shift2.begin.AddHours(9);
            shift2.shiftNumber = 1;
            shifts.Add(shift);
            shifts.Add(shift2);
        }
        else
        {
            employees = serializer.Deserialize<List<Employee>>(employeeJson);
            shifts = serializer.Deserialize<List<Shift>>(shiftsJson);
        }
        runModel(employees, shifts);
        Response.ContentType = "application/json; charset=utf-8";
        Response.Write(json);
        Response.End();

    }

    private void runModel(List<Employee> employees, List<Shift> shifts)
    {
        StreamWriter writer = File.CreateText(@"C:\Users\user\Desktop\cplex log\result9.txt");
        try
        {
            Cplex model = new Cplex();
          
            model.SetOut(writer);

            //------------------------------
            //---Variable initialization-----
            //------------------------------
            //Assignment variables
            IDictionary<string, IIntVar> assignVars = new Dictionary<string, IIntVar>();
            employees.ForEach(employee =>
            {
                shifts.ForEach(shift =>
               {
                   string name = getAssignVarName(employee, shift);
                   assignVars.Add(name, model.BoolVar(name));
               });
            });

            //Total assignment hours
            INumVar totalAssignHourVar = model.NumVar(0, Double.MaxValue, getTotalAssignVarName());

            //----------------------------------
            //---Constraints initialization-----
            //-----------------------------------

            //1) Min rest constraint 
            //2) Goal total assigned hours constraint
            ILinearNumExpr sumAssignHourExpr = model.LinearNumExpr();
            sumAssignHourExpr.AddTerm(-1.0, totalAssignHourVar);
            employees.ForEach(employee =>
            {
                shifts.ForEach(shift1 =>
                {
                    ILinearNumExpr sumOverlapExpr = model.LinearNumExpr();
                    string name1 = getAssignVarName(employee, shift1);
                    IIntVar assignVar1 = assignVars[name1];
                    sumOverlapExpr.AddTerm(1.0, assignVar1);
                    shifts.ForEach(shift2 =>
                    {
                        if (shift1 != shift2 && this.isDurationOverlap(shift1, shift2))
                        {
                            string name2 = getAssignVarName(employee, shift2);
                            sumOverlapExpr.AddTerm(1.0, assignVars[name2]);
                        }
                    });
                    model.AddLe(sumOverlapExpr, 1.0, "MinRestConst");

                    sumAssignHourExpr.AddTerm((shift1.end - shift1.begin).TotalMinutes, assignVar1);
                });


            });

            //3) No overassignment constraint
            shifts.ForEach(shift =>
            {
                ILinearNumExpr sumAssigsExpr = model.LinearNumExpr();
                employees.ForEach(employee =>
                {
                    string name1 = getAssignVarName(employee, shift);
                    IIntVar assignVar1 = assignVars[name1];
                    sumAssigsExpr.AddTerm(1.0, assignVar1);
                });
                model.AddLe(sumAssigsExpr, shift.shiftNumber, "NoOverAssignConst");
            });
            model.AddEq(sumAssignHourExpr, 0.0, "TotalAssignedHourConst");
            INumVar[] goalVars = { totalAssignHourVar };
            double[] coeffs = { 1.0 };
            model.AddMaximize(model.ScalProd(goalVars, coeffs));

            model.ExportModel(@"C:\Users\user\Desktop\cplex log\model1.lp");
            bool feasible = model.Solve();
            if (feasible)
            {
                double objVal = model.ObjValue;
                model.Output().WriteLine("Solution value = " + model.ObjValue);
                shifts.ForEach(shift =>
                {
                    ILinearNumExpr sumAssigsExpr = model.LinearNumExpr();
                    employees.ForEach(employee =>
                    {
                        string name = getAssignVarName(employee, shift);
                        
                    });
                    model.AddLe(sumAssigsExpr, shift.shiftNumber, "NoOverAssignConst");
                });

            }
            else
            {

            }
        }
        catch (System.Exception ex)
        {
            Response.ContentType = "application/json; charset=utf-8";
            Response.Write(ex.Message);
            Response.End();
        }
        writer.Close();

    }
    private bool isDurationOverlap(DateTime startA, DateTime endA, DateTime startB, DateTime endB)
    {
        return startA < endB && startB < endA;
    }
    private bool isDurationOverlap(Shift shiftA, Shift shiftB)
    {
        return this.isDurationOverlap(shiftA.begin, shiftA.end, shiftB.begin, shiftB.end);
    }
    private string getAssignVarName(Employee employee, Shift shift)
    {
        string name = employee.description + "@" + shift.description + "@" + shift.begin.ToString(dateFormat) + " to " + shift.end.ToString(dateFormat);
        return name;
    }
    private string getTotalAssignVarName()
    {
        return "TotalAssignmentHoursVar";
    }

    class Employee
    {
        public string description { get; set; }
    }
    class Shift
    {
        public string code { get; set; }
        public string description { get; set; }
        public int shiftNumber { get; set; }
        public DateTime begin { get; set; }
        public DateTime end { get; set; }
    }
}