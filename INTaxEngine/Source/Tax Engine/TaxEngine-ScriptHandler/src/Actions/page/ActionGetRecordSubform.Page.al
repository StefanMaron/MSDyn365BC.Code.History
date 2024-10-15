page 20168 "Action Get Record Subform"
{
    Caption = 'Get Record Field Mapping';
    PageType = ListPart;
    DataCaptionExpression = '';
    ShowFilter = false;
    PopulateAllFields = true;
    SourceTable = "Action Get Record Field";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(TableFieldName; TableFieldName2)
                {
                    Caption = 'Field';
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "Field Lookup";
                    Lookup = true;
                    ToolTip = 'Specifies the field name of Record.';
                    trigger OnValidate();
                    begin
                        AppObjectHelper.SearchTableField("Table ID", "Field ID", TableFieldName2);
                        Validate("Field ID");
                    end;

                    trigger OnLookup(var Text: Text): Boolean;
                    begin
                        AppObjectHelper.OpenFieldLookup("Table ID", "Field ID", TableFieldName2, Text);
                        Validate("Field ID");
                    end;
                }
                field(Variable; VariableName)
                {
                    Caption = 'Output Variable';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the variable name which will store the output.';
                    trigger OnValidate();
                    begin
                        ScriptSymbolsMgmt.SearchSymbol("Symbol Type"::Variable, "Variable ID", VariableName);
                        Validate("Variable ID");
                    end;

                    trigger OnLookup(var Text: Text): Boolean;
                    begin
                        ScriptSymbolsMgmt.OpenSymbolsLookup(
                            "Symbol Type"::Variable,
                            Text,
                            "Variable ID",
                            VariableName);

                        Validate("Variable ID");
                    end;
                }
            }
        }
    }

    var
        AppObjectHelper: Codeunit "App Object Helper";
        ScriptSymbolsMgmt: Codeunit "Script Symbols Mgmt.";
        TableFieldName2: Text[30];
        VariableName: Text[30];

    local procedure FormatLine();
    begin
        VariableName := ScriptSymbolsMgmt.GetSymbolName("Symbol Type"::Variable, "Variable ID");
        TableFieldName2 := AppObjectHelper.GetFieldName("Table ID", "Field ID");
    end;

    trigger OnAfterGetRecord();
    begin
        ScriptSymbolsMgmt.SetContext("Case ID", "Script ID");
        FormatLine();
    end;

    trigger OnAfterGetCurrRecord();
    begin
        ScriptSymbolsMgmt.SetContext("Case ID", "Script ID");
        FormatLine();
    end;
}