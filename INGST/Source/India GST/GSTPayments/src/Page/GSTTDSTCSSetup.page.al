page 18246 "GST TDS/TCS Setup"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "GST TDS/TCS Setup";
    Caption = 'GST TDS/TCS Setup';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether type is TDS/TCS.';
                }
                field("GST Component Code"; Rec."GST Component Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies GST component code.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TaxTypeSetup: Record "Tax Type Setup";
                        ScriptSymbolMgmt: Codeunit "Script Symbols Mgmt.";
                        ComponentName: Variant;
                        SymbolType: Enum "Symbol Type";
                        EmptyGuid: Guid;
                        ComponentID: integer;
                    begin
                        if not TaxTypeSetup.get() then
                            exit;
                        ScriptSymbolMgmt.SetContext(TaxTypeSetup.Code, EmptyGuid, EmptyGuid);
                        ScriptSymbolMgmt.OpenSymbolsLookup(SymbolType::Component, Text, ComponentID, ComponentName);
                        rec.validate("GST Component Code", ComponentName);
                    end;

                    trigger OnValidate()
                    var
                        TaxTypeSetup: Record "Tax Type Setup";
                        ScriptSymbolMgmt: Codeunit "Script Symbols Mgmt.";
                        SymbolType: Enum "Symbol Type";
                        ComponentName: Variant;
                        EmptyGuid: Guid;
                        ComponentID: integer;
                    begin
                        if not TaxTypeSetup.get() then
                            exit;
                        ComponentName := "GST Component Code";
                        ScriptSymbolMgmt.SetContext(TaxTypeSetup.Code, EmptyGuid, EmptyGuid);
                        ScriptSymbolMgmt.SearchSymbol(SymbolType::Component, ComponentID, ComponentName);
                        Rec.Validate("GST Component Code", ComponentName);
                    end;
                }
                field("Effective Date"; Rec."Effective Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the GST/TCS rate on this line comes into effect.';
                }
                field("GST TDS/TCS %"; Rec."GST TDS/TCS %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the relevant  GST TDS/TCS % for this particular combination.';
                }
                field("GST Jurisdiction"; Rec."GST Jurisdiction")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether GST Jurisdiction is Intrastate or Interstate.';
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
                        'GST TDS/TCS Setup',
                        CurrPage.ObjectId(false),
                        StrSubstNo(ComponentCodeMsg, Rec."GST Component Code"));
                end;
            }
        }
    }
    var
        ComponentCodeMsg: Label '%1', Comment = '%1=GSTComponent Code';
}