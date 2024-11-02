#if not CLEAN25
namespace Microsoft.Finance.FinancialReports;

using System.Environment;
using System.Integration;

codeunit 580 "Run Template Trial Balance"
{
    ObsoleteReason = 'Functionality replaced by "EXR Trial Balance Excel". Extend this report object with Excel layout instead.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';

    trigger OnRun()
    var
        ODataUtility: Codeunit ODataUtility;
        ObjectTypeParam: Option ,,,,,,,,"Page","Query";
        StatementType: Option BalanceSheet,SummaryTrialBalance,CashFlowStatement,StatementOfRetainedEarnings,AgedAccountsReceivable,AgedAccountsPayable,IncomeStatement;
    begin
        if not Confirm(DeprecatedMsg) then
            exit;
        if not (ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Phone, CLIENTTYPE::Tablet]) then
            ODataUtility.GenerateExcelTemplateWorkBook(ObjectTypeParam::Page, 'ExcelTemplateTrialBalance', true,
              StatementType::SummaryTrialBalance)
        else begin
            Message(OfficeMobileMsg);
            exit;
        end;
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";

        OfficeMobileMsg: Label 'Excel Reports cannot be opened in this environment because this version of Office does not support the file format.';
        DeprecatedMsg: Label 'This Excel report will be removed in an upcoming release, please use the report "Trial Balance (Preview)". Do you want to continue?';
}

#endif