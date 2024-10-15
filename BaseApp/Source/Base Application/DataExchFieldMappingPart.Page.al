page 1217 "Data Exch Field Mapping Part"
{
    Caption = 'Data Exchange Field Mapping';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Data Exch. Field Mapping";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Column No."; "Column No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the column in the external file that is mapped to the field in the Target Table ID field, when you are using an intermediate table for data import.';

                    trigger OnValidate()
                    begin
                        ColumnCaptionText := GetColumnCaption;
                    end;
                }
                field(ColumnCaptionText; ColumnCaptionText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Column Caption';
                    Editable = false;
                    ToolTip = 'Specifies the caption of the column in the external file that is mapped to the field in the Target Table ID field, when you are using an intermediate table for data import.';
                }
                field("Field ID"; "Field ID")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number of the field in the external file that is mapped to the field in the Target Table ID field, when you are using an intermediate table for data import.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        "Field": Record "Field";
                        TableFilter: Record "Table Filter";
                        FieldSelection: Codeunit "Field Selection";
                    begin
                        Field.SetRange(TableNo, "Table ID");
                        if FieldSelection.Open(Field) then begin
                            if Field."No." = "Field ID" then
                                exit;
                            TableFilter.CheckDuplicateField(Field);
                            FillSourceRecord(Field);
                            FieldCaptionText := GetFieldCaption;
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        FieldCaptionText := GetFieldCaption;
                    end;
                }
                field(FieldCaptionText; FieldCaptionText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Caption';
                    Editable = false;
                    ToolTip = 'Specifies the caption of the field in the external file that is mapped to the field in the Target Table ID field, when you are using an intermediate table for data import.';
                }
                field(Optional; Optional)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the map will be skipped if the field is empty. If you do not select this check box, then an export error will occur if the field is empty. When the Use as Intermediate Table check box is selected, the Validate Only check box specifies that the element-to-field map is not used to convert data, but only to validate data.';
                }
                field(Multiplier; Multiplier)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Transformation Rule"; "Transformation Rule")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the rule that transforms imported text to a supported value before it can be mapped to a specified field in Microsoft Dynamics 365. When you choose a value in this field, the same value is entered in the Transformation Rule field in the Data Exch. Field Mapping Buf. table and vice versa.';
                }
                field("Overwrite Value"; "Overwrite Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the current value will be overwritten by a new value.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ColumnCaptionText := GetColumnCaption;
        FieldCaptionText := GetFieldCaption;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ColumnCaptionText := '';
        FieldCaptionText := '';
    end;

    var
        [InDataSet]
        ColumnCaptionText: Text;
        [InDataSet]
        FieldCaptionText: Text;
}

