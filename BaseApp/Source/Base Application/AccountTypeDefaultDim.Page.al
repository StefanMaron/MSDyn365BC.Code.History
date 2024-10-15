page 541 "Account Type Default Dim."
{
    Caption = 'Account Type Default Dim.';
    DataCaptionFields = "Dimension Code";
    PageType = List;
    SourceTable = "Default Dimension";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Table ID"; "Table ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a table ID for the account type if you are specifying default dimensions for an entire account type.';

                    trigger OnValidate()
                    begin
                        TableIDOnAfterValidate;
                    end;
                }
                field("Table Caption"; "Table Caption")
                {
                    ApplicationArea = Dimensions;
                    DrillDown = false;
                    ToolTip = 'Specifies the table name for the account type you wish to define a default dimension for.';
                }
                field("Dimension Value Code"; "Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value code to suggest as the default dimension.';
                }
                field("Value Posting"; "Value Posting")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies how default dimensions and their values must be used.';
                }
                field(AllowedValues; "Allowed Values Filter")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension values that can be used for the selected account.';

                    trigger OnAssistEdit()
                    var
                        DimMgt: Codeunit DimensionManagement;
                    begin
                        TestField("Value Posting", "Value Posting"::"Code Mandatory");
                        DimMgt.OpenAllowedDimValuesPerAccount(Rec);
                        CurrPage.Update();
                    end;
                }
                field("Automatic Create"; "Automatic Create")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies if a value will be created automatic';
                    Visible = false;
                }
                field("Dimension Description Field ID"; "Dimension Description Field ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the id of dimension description field';
                    Visible = false;
                }
                field("Dimension Description Update"; "Dimension Description Update")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the rule for dimension description update';
                    Visible = false;
                }
                field("Dimension Description Format"; "Dimension Description Format")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a description format for the dimension';
                    Visible = false;
                }
                field("Automatic Cr. Value Posting"; "Automatic Cr. Value Posting")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies rule for automatic create';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Check Value Posting")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Check Value Posting';
                    Ellipsis = true;
                    Image = "Report";
                    RunObject = Report "Check Value Posting";
                    ToolTip = 'Find out whether the value posting rules that are specified for individual default dimensions conflict with the rules specified for the account type default dimensions. For example, if you have set up a customer account with value posting No Code and then specify that all customer accounts should have a particular default dimension value code, this report will show that a conflict exists.';
                }
                action("Update aut. def. dimensions")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Update aut. def. dimensions';
                    Image = MapDimensions;
                    ToolTip = 'Update default dimensions.';

                    trigger OnAction()
                    var
                        DefaultDimension: Record "Default Dimension";
                        DimensionManagement: Codeunit DimensionManagement;
                    begin
                        // NAVCZ
                        CurrPage.SetSelectionFilter(DefaultDimension);
                        DimensionManagement.UpdateAllAutDim(DefaultDimension);
                        // NAVCZ
                    end;
                }
            }
        }
    }

    local procedure TableIDOnAfterValidate()
    begin
        CalcFields("Table Caption");
    end;
}

