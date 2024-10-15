page 26585 "XML Element Expression Lines"
{
    AutoSplitKey = true;
    Caption = 'XML Element Expression Lines';
    PageType = Worksheet;
    SourceTable = "XML Element Expression Line";

    layout
    {
        area(content)
        {
            field(ExpressionValueControl; ExpressionValue)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Expression Value';
                Editable = false;
            }
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Source; Source)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source associated with the XML element expression line.';

                    trigger OnValidate()
                    begin
                        SourceOnAfterValidate;
                    end;
                }
                field("Field Name"; "Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the field name associated with the XML element expression line.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        "Field": Record "Field";
                        FieldSelection: Codeunit "Field Selection";
                    begin
                        Field.SetRange(TableNo, "Table ID");
                        if FieldSelection.Open(Field) then begin
                            Validate("Field ID", Field."No.");
                            CurrPage.Update;

                            ExpressionValue := UpdateRequisiteValue(false);
                        end;
                    end;
                }
                field(Value; Value)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value associated with the XML element expression line.';
                }
                field("String Before"; "String Before")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the string that is before the line on which the XML expression is based.';

                    trigger OnValidate()
                    begin
                        if SpaceEntered then begin
                            "String Before" := ' ';
                            SpaceEntered := false;
                        end;
                    end;
                }
                field("String After"; "String After")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the string that is after the line on which the XML expression is based.';

                    trigger OnValidate()
                    begin
                        if SpaceEntered then begin
                            "String After" := ' ';
                            SpaceEntered := false;
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        ExpressionValue := GetExpressionValue;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateReferences;
    end;

    trigger OnOpenPage()
    begin
        ExpressionValue := GetExpressionValue;
        OnActivateForm;
    end;

    var
        XMLElementLine: Record "XML Element Line";
        ExpressionValue: Text[250];
        SpaceEntered: Boolean;

    [Scope('OnPrem')]
    procedure GetExpressionValue(): Text[250]
    begin
        if XMLElementLine.Get("Report Code", "Base XML Element Line No.") then
            exit(XMLElementLine.Value);

        exit('');
    end;

    local procedure SourceOnAfterValidate()
    begin
        CalcFields("Field Name");
    end;

    local procedure OnActivateForm()
    begin
        ExpressionValue := GetExpressionValue;
    end;
}

