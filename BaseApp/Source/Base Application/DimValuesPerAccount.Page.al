page 545 "Dim. Values per Account"
{
    Caption = 'Dimension Values per Account';
    DataCaptionFields = "Dimension Code";
    PageType = List;
    SourceTable = "Default Dimension";
    SourceTableView = WHERE("Value Posting" = CONST("Code Mandatory"));
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(TableID; "Table ID")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies a table ID for the account type if you are specifying default dimensions for an entire account type.';
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = Dimensions;
                    DrillDown = false;
                    ToolTip = 'Specifies the table name for the account type you wish to define a default dimension for.';
                }
                field(AccountNo; "No.")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the account number you wish to define a default dimension for.';
                }
                field(AllowedValues; "Allowed Values Filter")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension values that can be used for the selected account.';

                    trigger OnAssistEdit()
                    var
                        DimMgt: Codeunit DimensionManagement;
                    begin
                        DimMgt.OpenAllowedDimValuesPerAccount(Rec);
                    end;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(SetupAllowedValues)
            {
                ApplicationArea = Dimensions;
                Caption = 'Setup Allowed Values';
                ToolTip = 'Specifies the dimension values that can be used for the selected account.';
                Image = Dimensions;

                trigger OnAction();
                var
                    DimMgt: Codeunit DimensionManagement;
                begin
                    DimMgt.OpenAllowedDimValuesPerAccount(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(SetupAllowedValues_Promoted; SetupAllowedValues)
                {
                }
            }
        }
    }

}