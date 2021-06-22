page 8623 "Config. Package Filters"
{
    Caption = 'Config. Package Filters';
    PageType = List;
    SourceTable = "Config. Package Filter";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Field ID"; "Field ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the field on which you want to filter records in the configuration table.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        "Field": Record "Field";
                        ConfigPackageMgt: Codeunit "Config. Package Management";
                        FieldSelection: Codeunit "Field Selection";
                    begin
                        ConfigPackageMgt.SetFieldFilter(Field, "Table ID", 0);
                        if FieldSelection.Open(Field) then begin
                            Validate("Field ID", Field."No.");
                            CurrPage.Update(true);
                        end;
                    end;
                }
                field("Field Name"; "Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the field on which you want to filter records in the configuration table.';
                }
                field("Field Caption"; "Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the field caption of the field on which you want to filter records in the configuration table.';
                }
                field("Field Filter"; "Field Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the field filter value for a configuration package filter. By setting a value, you specify that only records with that value are included in the configuration package.';
                }
            }
        }
    }

    actions
    {
    }
}

