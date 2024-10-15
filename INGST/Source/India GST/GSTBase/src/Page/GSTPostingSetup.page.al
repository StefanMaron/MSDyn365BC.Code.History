page 18003 "GST Posting Setup"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "GST Posting Setup";
    Caption = 'GST Posting Setup';
    RefreshOnActivate = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("State Code"; "State Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies state code.';
                }
                field(GSTGroupCod; ComponentName)
                {
                    Caption = 'GST Component Code';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies GST component code.';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TaxTypeSetup: Record "Tax Type Setup";
                        ComponentName: Variant;
                    begin
                        if not TaxTypeSetup.get() then
                            exit;
                        ScriptSymbolMgmt.SetContext(TaxTypeSetup.Code, EmptyGuid, EmptyGuid);
                        ScriptSymbolMgmt.OpenSymbolsLookup(
                            SymbolType::Component,
                            Text,
                            "Component ID",
                            ComponentName);
                        Validate("Component ID");
                        FormatLine();
                    end;

                    trigger OnValidate()
                    var
                        TaxTypeSetup: Record "Tax Type Setup";
                        ComponentName: Variant;
                    begin
                        if not TaxTypeSetup.get() then
                            exit;
                        ScriptSymbolMgmt.SetContext('GST', EmptyGuid, EmptyGuid);
                        ScriptSymbolMgmt.SearchSymbol(SymbolType::Component, "Component ID", ComponentName);
                        Validate("Component ID");
                        FormatLine();
                    end;

                }
                field("Receivable Account"; "Receivable Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies state-wise receivable account for each component. ';
                }
                field("Payable Account"; "Payable Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies state-wise payable account for each component. ';
                }
                field("Receivable Account (Interim)"; "Receivable Account (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies state-wise receivable account (interim) for each component. ';
                }
                field("Payables Account (Interim)"; "Payables Account (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies state-wise payable account (interim) for each component. ';
                }
                field("Expense Account"; "Expense Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies state-wise expense account for each component. ';
                }
                field("Refund Account"; "Refund Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies state-wise refund account for each component. ';
                }
                field("Receivable Acc. Interim (Dist)"; "Receivable Acc. Interim (Dist)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies state-wise receivable account interim (Dist) for each component. ';
                }
                field("Receivable Acc. (Dist)"; "Receivable Acc. (Dist)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies state-wise receivable account (Dist) for each component. ';
                }
                field("GST Credit Mismatch Account"; "GST Credit Mismatch Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies state-wise GST credit mismatch account for each component. ';
                }
                field("GST TDS Receivable Account"; "GST TDS Receivable Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies state-wise GST TDS receivable account  for each component. ';
                }
                field("GST TCS Receivable Account"; "GST TCS Receivable Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies state-wise GST TCS receivable account for each component. ';
                }
                field("GST TCS Payable Account"; "GST TCS Payable Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies state-wise GST TCS payable account for each component. ';
                }
                field("IGST Payable A/c (Import)"; "IGST Payable A/c (Import)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies state-wise IGST payable account (import) for each component. ';
                }
            }
        }
    }


    actions
    {
        area(Processing)
        {
            action(EditInExcel)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit in Excel';
                Image = Excel;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Send the data in the page to an Excel file for analysis or editing';

                trigger OnAction()
                var
                    ODataUtility: Codeunit ODataUtility;
                begin
                    ODataUtility.EditWorksheetInExcel(
                        'GST Posting Setup',
                        CurrPage.ObjectId(false),
                        StrSubstNo(CodeValueLbl,
                        Rec."State Code"));
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        FormatLine();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        FormatLine();
    end;

    local procedure FormatLine()
    var
        TaxTypeSetup: Record "Tax Type Setup";
    begin
        Clear(ScriptSymbolMgmt);
        if not TaxTypeSetup.Get() then
            exit;
        TaxTypeSetup.TestField(Code);
        ScriptSymbolMgmt.SetContext(TaxTypeSetup.Code, EmptyGuid, EmptyGuid);

        if "Component ID" <> 0 then
            ComponentName := ScriptSymbolMgmt.GetSymbolName(SymbolType::Component, "Component ID")
        else
            ComponentName := '';
    end;

    Var
        ScriptSymbolMgmt: Codeunit "Script Symbols Mgmt.";
        SymbolType: Enum "Symbol Type";
        EmptyGuid: Guid;
        ComponentName: Text[30];
        CodeValueLbl: Label 'Code %1', Comment = '%1 = State Code';
}