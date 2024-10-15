dotnet
{
    assembly("Microsoft.Office.Interop.Excel")
    {
        Version = '15.0.0.0';
        Culture = 'neutral';
        PublicKeyToken = '71e9bce111e9429c';

        type("Microsoft.Office.Interop.Excel.ApplicationClass"; "ApplicationClass0")
        {
        }

        type("Microsoft.Office.Interop.Excel.WorkbookClass"; "WorkbookClass")
        {
        }

        type("Microsoft.Office.Interop.Excel.WorksheetClass"; "WorksheetClass")
        {
        }

        type("Microsoft.Office.Interop.Excel.Worksheets"; "Worksheets")
        {
        }

        type("Microsoft.Office.Interop.Excel.Range"; "Range")
        {
        }

        type("Microsoft.Office.Interop.Excel.XlRangeValueDataType"; "XlRangeValueDataType")
        {
        }

        type("Microsoft.Office.Interop.Excel.XlDeleteShiftDirection"; "XlDeleteShiftDirection")
        {
        }

        type("Microsoft.Office.Interop.Excel.XlReferenceStyle"; "XlReferenceStyle")
        {
        }
    }

    assembly("Microsoft.Dynamics.NAV.RU.ExcelReportBuilder")
    {
        Version = '15.0.0.0';
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