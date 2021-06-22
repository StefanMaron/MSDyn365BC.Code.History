codeunit 6302 "Power BI Label Mgt."
{
    // // Codeunit for generating the static values that Power BI reports use for titles or other
    // // text labels. These values are exposed through a web service for page 6318. This approach
    // // lets reports get values translated for the user's locale rather than hardcoding English.


    trigger OnRun()
    begin
    end;

    var
        CRM_SalesOpportuntiesByCompany_KeyTxt: Label 'CRM_SalesOpportuntiesByCompany', Locked = true;
        CRM_SalesOpportuntiesByCompany_ValueTxt: Label 'Estimated Value by Customer Name';
        CRM_CompletedByStatus_KeyTxt: Label 'CRM_CompletedByStatus', Locked = true;
        CRM_CompletedByStatus_ValueTxt: Label 'Completed by Status & Company Name';
        CRM_OpportunityDashboard_KeyTxt: Label 'CRM_OpportunityDashboard', Locked = true;
        CRM_OpportunityDashboard_ValueTxt: Label 'Opportunity Dashboard';
        CRM_Details1_KeyTxt: Label 'CRM_Details1', Locked = true;
        CRM_Details1_ValueTxt: Label 'Back to Report';
        CRM_Details2_KeyTxt: Label 'CRM_Details2', Locked = true;
        CRM_Details2_ValueTxt: Label 'CRM Details';
        CRM_SnapShot_KeyTxt: Label 'CRM_SnapShot', Locked = true;
        CRM_SnapShot_ValueTxt: Label 'Opportunity Snapshot';
        Finance_NetChangeMargin_KeyTxt: Label 'Finance_NetChangeMargin', Locked = true;
        Finance_NetChangeMargin_ValueTxt: Label 'Actual Net Change by Date & KPI Name';
        Finance_FinancialDashboard_KeyTxt: Label 'Finance_FinancialDashboard', Locked = true;
        Finance_FinancialDashboard_ValueTxt: Label 'Financial Dashboard';
        Finance_NetChangebyDays_KeyTxt: Label 'Finance_NetChangebyDays', Locked = true;
        Finance_NetChangebyDays_ValueTxt: Label 'Net Change by Date & KPI Name';
        Finance_NetChangeRevenueExpendituresInterest_KeyTxt: Label 'Finance_NetChangeRevenueExpendituresInterest', Locked = true;
        Finance_NetChangeRevenueExpendituresInterest_ValueTxt: Label 'Net Change by Date & KPI Name';
        Finance_MiniTrialBalance_KeyTxt: Label 'Finance_MiniTrialBalance', Locked = true;
        Finance_MiniTrialBalance_ValueTxt: Label 'Mini Trial Balance';
        Finance_KPIDetails1_KeyTxt: Label 'Finance_KPI Details1', Locked = true;
        Finance_KPIDetails1_ValueTxt: Label 'Net Change Details';
        Finance_KPIDetails2_KeyTxt: Label 'Finance_KPI Details2', Locked = true;
        Finance_KPIDetails2_ValueTxt: Label 'Back to Report';
        Sales_ItemSales_KeyTxt: Label 'Sales_ItemSales', Locked = true;
        Sales_ItemSales_ValueTxt: Label 'Top 5 Items Sold by Quantity';
        Sales_ItemSalesDashboard_KeyTxt: Label 'Sales_ItemSalesDashboard', Locked = true;
        Sales_ItemSalesDashboard_ValueTxt: Label 'Item Sales Dashboard';
        Sales_CustomerSales_KeyTxt: Label 'Sales_CustomerSales', Locked = true;
        Sales_CustomerSales_ValueTxt: Label 'Top 5 Customers by Sales Amount';
        Sales_CustomerSalesDashboard_KeyTxt: Label 'Sales_CustomerSalesDashboard', Locked = true;
        Sales_CustomerSalesDashboard_ValueTxt: Label 'Customer Sales Dashboard';
        Sales_CustomerSalesTimeline_KeyTxt: Label 'Sales_CustomerSalesTimeline', Locked = true;
        Sales_CustomerSalesTimeline_ValueTxt: Label 'Sales Timeline';
        Sales_Details_SalesDetails1_KeyTxt: Label 'Sales_Details_SalesDetails1', Locked = true;
        Sales_Details_SalesDetails1_ValueTxt: Label 'Back to Report';
        Sales_Details_SalesDetails2_KeyTxt: Label 'Sales_Details_SalesDetails2', Locked = true;
        Sales_Details_SalesDetails2_ValueTxt: Label 'Sales Details';
        JobsProfit_KeyTxt: Label 'JobsProfit', Locked = true;
        JobsProfit_ValueTxt: Label 'Cost vs. Invoiced Amount with Profit';
        JobsDashboard_KeyTxt: Label 'JobsDashboard', Locked = true;
        JobsDashboard_ValueTxt: Label 'Jobs Dashboard';
        VendorList_VendorPurchases_KeyTxt: Label 'VendorList_VendorPurchases', Locked = true;
        VendorList_VendorPurchases_ValueTxt: Label 'Vendor Purchases';
        VendorList_PurchaseInvoiceList_KeyTxt: Label 'VendorList_PurchaseInvoiceList', Locked = true;
        VendorList_PurchaseInvoiceList_ValueTxt: Label 'Document Number';

    procedure GetReportLabels(var TempPowerBIReportLabels: Record "Power BI Report Labels" temporary)
    begin
        // Fills the given temp table with all the default key-value pairs hardcoded into this codeunit.
        // Key text should always be locked, and Value text should always be translated.
        InsertLabel(TempPowerBIReportLabels, CRM_SalesOpportuntiesByCompany_KeyTxt, CRM_SalesOpportuntiesByCompany_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, CRM_CompletedByStatus_KeyTxt, CRM_CompletedByStatus_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, CRM_OpportunityDashboard_KeyTxt, CRM_OpportunityDashboard_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, CRM_Details1_KeyTxt, CRM_Details1_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, CRM_Details2_KeyTxt, CRM_Details2_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, CRM_SnapShot_KeyTxt, CRM_SnapShot_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Finance_NetChangeMargin_KeyTxt, Finance_NetChangeMargin_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Finance_FinancialDashboard_KeyTxt, Finance_FinancialDashboard_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Finance_NetChangebyDays_KeyTxt, Finance_NetChangebyDays_ValueTxt);
        InsertLabel(TempPowerBIReportLabels,
          Finance_NetChangeRevenueExpendituresInterest_KeyTxt, Finance_NetChangeRevenueExpendituresInterest_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Finance_MiniTrialBalance_KeyTxt, Finance_MiniTrialBalance_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Finance_KPIDetails1_KeyTxt, Finance_KPIDetails1_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Finance_KPIDetails2_KeyTxt, Finance_KPIDetails2_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_ItemSales_KeyTxt, Sales_ItemSales_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_ItemSalesDashboard_KeyTxt, Sales_ItemSalesDashboard_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_CustomerSales_KeyTxt, Sales_CustomerSales_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_CustomerSalesDashboard_KeyTxt, Sales_CustomerSalesDashboard_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_CustomerSalesTimeline_KeyTxt, Sales_CustomerSalesTimeline_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_Details_SalesDetails1_KeyTxt, Sales_Details_SalesDetails1_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, Sales_Details_SalesDetails2_KeyTxt, Sales_Details_SalesDetails2_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, JobsProfit_KeyTxt, JobsProfit_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, JobsDashboard_KeyTxt, JobsDashboard_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, VendorList_VendorPurchases_KeyTxt, VendorList_VendorPurchases_ValueTxt);
        InsertLabel(TempPowerBIReportLabels, VendorList_PurchaseInvoiceList_KeyTxt, VendorList_PurchaseInvoiceList_ValueTxt);
    end;

    local procedure InsertLabel(var TempPowerBIReportLabels: Record "Power BI Report Labels" temporary; LabelName: Text[100]; LabelText: Text[250])
    begin
        // Inserts the given key-value pair into the temp table.
        TempPowerBIReportLabels."Label ID" := LabelName;
        TempPowerBIReportLabels."Text Value" := LabelText;
        TempPowerBIReportLabels.Insert();
    end;
}

