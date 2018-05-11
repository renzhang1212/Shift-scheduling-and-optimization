<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="_Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Shift scheduling in ATC</title>
    </head>
    <body>
        <link href="https://fonts.googleapis.com/css?family=Roboto" rel="stylesheet" type="text/css" />
        <style>
            body {
                font-family: Roboto, Times;
            }

            h1 {
                display: inline-block;
            }
        </style>
        <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.1.0/css/bootstrap.min.css" integrity="sha384-9gVQ4dYFwwWSjIDZnLEWnxCjeSWFphJiwGPXr1jddIhOegiu1FwO5qRGvFXOdJZ4" crossorigin="anonymous">
        <link rel="stylesheet" type="text/css" href="dist/jquery.stacked-gantt.css">

        <script src="libs/jquery/jquery.js"></script>
        <script src="dist/jquery.stacked-gantt.js"></script>
        <script>

            function createDate(time, daysToSum) {
                var split = time.split(' ');
                var dates = split[0].split('/');
                var times = split[1].split(':');
                var ret = new Date(dates[0], parseInt(dates[1]) - 1, dates[2], times[0], times[1], 0, 0);
            
                if (daysToSum) ret.setDate(ret.getDate() + daysToSum);
                return ret;
            }

            var employees = ["William Nation", "Carmelita Mcfee", "Flo Lightle", "Ute Gough", "Cassy Fegley", "Vernie Englehart", "Dante Pettigrew", "Hershel Buller",
            "Leeann Mcwaters", "Valrie Jasper", "Chelsey Franchi", "Romaine Georges", "Charlyn Fleishman", "Ilona Lall", "Librada Huth", "Cayla Luechtefeld",
            "Sha Chrysler"].sort();
            var startDateInStr = '2018/6/4 07:00';
            var endDateInStr = '2018/6/30 23:59';
            var data = employees.map(e =>({ "description": e, "activities": [{ code: 'STR', description: 'Start', begin: createDate(startDateInStr), end: createDate(startDateInStr) }, { code: 'END', description: 'End', begin: createDate(endDateInStr), end: createDate(endDateInStr) }] }));
            
            var generalMarkers = [
                {
                    description: "Start of the schedule", when: createDate(startDateInStr), color: "#e942cd", width: "5px",
                    onClick: function (marker) {
                       // alert(marker.description);
                    }
                }, {
                    description: "End of the schedule", when: createDate(endDateInStr), color: "#e942cd", width: "5px",
                    onClick: function (marker) {
                        // alert(marker.description);
                    }
                }
            ];

            var generalHighlights = [
                { begin: createDate('2018/6/1 08:00'), end: createDate('2018/6/1 18:00'), color: "#5cea67" },
                { begin: createDate('2018/6/1 20:00'), end: createDate('2018/6/1 02:15', 1) },
            ];
            var activityStyles = {
                'STDUP': { color: "#8e87ea", height: "30px" },
                'SB': { color: "#8e87ea", height: "30px" },
                'DEV': { color: "#ea8787" },
                'DEVOPS': { color: "#e8e44e" },
            };
            var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
            var options = {
                data: data,
                generalMarkers: generalMarkers,
                style: {
                    months: months,
                    activityStyle: activityStyles,
                    showDateOnHeader: true,
                    dateHeaderFormat: function (date) {
                        var days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
                        var months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

                        return days[date.getDay()] + ", " + months[date.getMonth()] + " " + date.getDate() + "th - " + date.getFullYear();
                    },
                    descriptionContainerWidth: '200px'
                }
            };
            var shiftPatterns = [{ "days": "1,2,3,4,5,6,7", start: "07:00", end: "16:00", quantity: 15, "description": "Day shifts" },
                { "days": "1,2,3,4,5,6,7", start: "15:00", end: "24:00", quantity: 15, "description": "Evening shifts" },
                { "days": "1,2,3,4,5,6,7", start: "23:00", end: "32:00", quantity: 15, "description": "Midnight shifts" }];
            var data2 = [];
            var totalShifts = [];
            for (var i = 0; i < shiftPatterns.length; i++) {
                var shiftBanks = [];
                for (var d = createDate(startDateInStr, 0) ; d <= createDate(startDateInStr, 30) ; d.setDate(d.getDate() + 1)) {
                    var shiftPattern = shiftPatterns[i];
                    var dateInStr = d.getFullYear() + "/" + (d.getMonth() +1) + "/" + d.getDate();
                    var shift = { code: "SB", description: shiftPattern.description, "shiftNumber": shiftPattern.quantity, begin: createDate(dateInStr + " " + shiftPattern.start), end: createDate(dateInStr + " " + shiftPattern.end) };
                    shiftBanks.push(shift);
                    totalShifts.push(shift);
                }
                data2.push({ "description": shiftPattern.description, "activities": shiftBanks });
            }
            var options2 = {
                data: data2,
                generalMarkers: generalMarkers,
                style: {
                    months: months,
                    activityStyle: activityStyles,
                    showDateOnHeader: true,
                    dateHeaderFormat: function (date) {
                        var days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
                        var months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

                        return days[date.getDay()] + ", " + months[date.getMonth()] + " " + date.getDate() + "th - " + date.getFullYear();
                    },
                    descriptionContainerWidth: '200px'
                }
            };
            $(document).ready(function () {
                var $timeline = $('#timeline').stackedGantt(options);
                var $timeline = $('#shiftbank').stackedGantt(options2);
            });

  	</script>

        <div>
            <h1>Shift scheduleing in ATC</h1>
          
        </div>
   
         <button type="button" id="optimizeBtn"class="btn btn-success">Optimize shift assignment</button>
          <br />
           <br />
        <div id="shiftbank" style="width: 100%"></div>
        <br />
       
        <br />
        <div id="timeline" style="width: 100%"></div>


    </body>
    </html>
    <script>
        $(document).ready(function () {
            var formBasic = function () {
                $.ajax({
                    type: 'POST',
                    data: { "employees" : JSON.stringify(data), "shifts" : JSON.stringify(totalShifts)},
                    dataType: 'json',
                    url: 'optimize.aspx',
                    error: function (request, err) {
                        alert(err);
                        return false;
                    },
                    complete: function (output) {
                        alert(output.responseText);
                    }
                });
                return false;
            };

            $("#optimizeBtn").on("click", function (e) {
                e.preventDefault();
                formBasic();
            });
        });
    </script>
</asp:Content>
