page 20251 "Rate Setup"
{
    PageType = List;
    SourceTable = "Tax Rate Column Setup";
    SourceTableView = sorting("Sequence");
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Column Type"; "Column Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of Rate column - Range, Value or Output value.';
                }
                field(Name; "Column Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Caption of the column.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data type of the rate column.';
                }
                field(Sequence; Sequence)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sequence in which columns will appear on  tax rates page.';
                }
                field(LinkedAttributeName; LinkedAttributeName2)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Linked Attribute Name';
                    ToolTip = 'Specifies the name of attribute. This will be only applicable where column type is either Range, Value or Output value.';
                    Editable = ("Column Type" = "Column Type"::Value);

                    trigger OnValidate()
                    begin
                        ScriptSymbolsMgmt.SetContext("Tax Type", EmptyGuid, EmptyGuid);
                        if "Column Type" = "Column Type"::Value then
                            ScriptSymbolsMgmt.SearchSymbolOfType(
                                "Symbol Type"::"Tax Attributes",
                                DataTypeMgmt.GetAttributeDataTypeToVariableDataType(Type),
                                "Linked Attribute ID",
                                LinkedAttributeName2);
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ScriptSymbolsMgmt.SetContext("Tax Type", EmptyGuid, EmptyGuid);
                        if "Column Type" = "Column Type"::Value then
                            ScriptSymbolsMgmt.OpenSymbolsLookupOfType(
                                "Symbol Type"::"Tax Attributes",
                                LinkedAttributeName2,
                                DataTypeMgmt.GetAttributeDataTypeToVariableDataType(Type),
                                "Linked Attribute ID",
                                LinkedAttributeName2);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowMatrix)
            {
                Caption = 'Show Matrix';
                Image = ShowMatrix;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Opens the tax rates for based on rate column setup.';
                trigger OnAction();
                var
                    TaxConfiguration: Record "Tax Rate";
                    TaxConfigMatrix: page "Tax Rates";
                begin
                    TaxConfiguration.SetRange("Tax Type", "Tax Type");
                    TaxConfigMatrix.SetTaxType("Tax Type");
                    TaxConfigMatrix.SetTableView(TaxConfiguration);
                    TaxConfigMatrix.Run();
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(LinkedAttributeName2);
    end;

    trigger OnAfterGetRecord()
    begin
        if "Linked Attribute ID" <> 0 then
            LinkedAttributeName2 := AttributeManagement.GetAttributeName("Linked Attribute ID")
        else
            LinkedAttributeName2 := '';
    end;

    var
        AttributeManagement: Codeunit "Tax Attribute Management";
        DataTypeMgmt: Codeunit "Use Case Data Type Mgmt.";
        ScriptSymbolsMgmt: Codeunit "Script Symbols Mgmt.";
        LinkedAttributeName2: Text[30];
        EmptyGuid: Guid;
}