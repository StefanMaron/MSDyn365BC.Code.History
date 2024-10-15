namespace Microsoft.Finance.FinancialReports;

using System.Environment;
using System.Integration;

codeunit 581 "Run Template Aged Acc. Pay."
{

    trigger OnRun()
    var
        ODataUtility: Codeunit ODataUtility;
        ObjectTypeParam: Option ,,,,,,,,"Page","Query";
        StatementType: Option BalanceSheet,SummaryTrialBalance,CashFlowStatement,StatementOfRetainedEarnings,AgedAccountsReceivable,AgedAccountsPayable,IncomeStatement;
    begin
        if not (ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Phone, CLIENTTYPE::Tablet]) then
            ODataUtility.GenerateExcelTemplateWorkBook(ObjectTypeParam::Page, 'ExcelTemplateAgedAccountsPayable', true,
              StatementType::AgedAccountsPayable)
        else begin
            Message(OfficeMobileMsg);
            exit;
        end;
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";

        OfficeMobileMsg: Label 'Excel Reports cannot be opened in this environment because this version of Office does not support the file format.';
}

