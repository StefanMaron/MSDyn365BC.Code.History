page 20297 "Use Case Table Link Dialog"
{
    DelayedInsert = true;
    Caption = 'Table Linking';
    PageType = StandardDialog;
    DataCaptionExpression = '';
    PopulateAllFields = true;
    SourceTable = "Use Case Field Link";

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
                    ToolTip = 'Specifies the name of the field.';
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
                field("Filter Type"; "Filter Type")
                {
                    Caption = 'Type';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of filter.';
                }
                field(FilterValue; FilterValue2)
                {
                    Caption = 'Value';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of filter, this can be either a constant value or it can be also derived from a Lookup.';
                    trigger OnValidate();
                    begin
                        AppObjectHelper.SearchTableField("Lookup Table ID", "Lookup Field ID", FilterValue2);
                        Validate(Value, FilterValue2);
                        FormatLine();
                    end;

                    trigger OnLookup(var Text: Text): Boolean;
                    begin
                        if "Filter Type" = "Filter Type"::CONST then
                            AppObjectHelper.OpenFieldLookup("Lookup Table ID", "Lookup Field ID", FilterValue2, Text);

                        FormatLine();
                    end;
                }
            }
        }
    }

    procedure SetCurrentRecord(var UseCaseEventTableLink2: Record "Use Case Event Table Link");
    begin
        UseCaseEventTableLink := UseCaseEventTableLink2;
        TestRecord();

        FilterGroup := 2;
        SetRange("Case ID", UseCaseEventTableLink."Case ID");
        SetRange("Table Filter ID", UseCaseEventTableLink.ID);
        SetRange("Table ID", UseCaseEventTableLink."Table ID");
        FilterGroup := 0;
    end;

    local procedure TestRecord();
    begin
        UseCaseEventTableLink.TestField(ID);
    end;

    local procedure FormatLine();
    begin
        FilterValue2 := Value;
    end;

    trigger OnOpenPage();
    begin
        TestRecord();
    end;

    trigger OnAfterGetRecord();
    begin
        TableFieldName2 := AppObjectHelper.GetFieldName("Table ID", "Field ID");
        FormatLine();
    end;

    trigger OnNewRecord(BelowxRec: Boolean);
    begin
        "Case ID" := UseCaseEventTableLink."Case ID";
        "Table Filter ID" := UseCaseEventTableLink.ID;
        "Table ID" := UseCaseEventTableLink."Table ID";
        "Lookup Table ID" := UseCaseEventTableLink."Lookup Table ID";
    end;

    trigger OnAfterGetCurrRecord();
    begin
        TableFieldName2 := AppObjectHelper.GetFieldName("Table ID", "Field ID");
        if "Lookup Field ID" <> 0 then
            Value := AppObjectHelper.GetFieldName("Lookup Table ID", "Lookup Field ID");
        FormatLine();
    end;

    var
        UseCaseEventTableLink: Record "Use Case Event Table Link";
        AppObjectHelper: Codeunit "App Object Helper";
        TableFieldName2: Text[30];
        FilterValue2: Text[30];
}