dotnet
{
    assembly("Microsoft.Dynamics.NAV.RU.ExcelReportBuilder")
    {
        Culture = 'neutral';
        PublicKeyToken = '31bf3856ad364e35';

        type("Microsoft.Dynamics.NAV.RU.ExcelReportBuilder.ReportBuilder"; "ReportBuilder")
        {
        }

        type("Microsoft.Dynamics.NAV.RU.ExcelReportBuilder.HeightInfo"; "HeightInfo")
        {
        }
    }

    assembly("Microsoft.Dynamics.Nav.Integration.Office")
    {
        type("Microsoft.Dynamics.Nav.Integration.Office.Excel.ExcelHelper"; "ExcelHelper")
        {
        }

        type("Microsoft.Dynamics.Nav.Integration.Helper"; "Helper")
        {
        }
    }
}