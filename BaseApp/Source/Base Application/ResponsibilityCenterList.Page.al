page 5715 "Responsibility Center List"
{
    AdditionalSearchTerms = 'department,office,location,site';
    ApplicationArea = Location;
    Caption = 'Responsibility Centers';
    CardPageID = "Responsibility Center Card";
    Editable = false;
    PageType = List;
    SourceTable = "Responsibility Center";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the responsibility center list code.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the name.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location of the responsibility center.';
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
        area(navigation)
        {
            group("&Resp. Ctr.")
            {
                Caption = '&Resp. Ctr.';
                Image = Dimensions;
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = CONST(5714),
                                      "No." = FIELD(Code);
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            RespCenter: Record "Responsibility Center";
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(RespCenter);
                            DefaultDimMultiple.SetMultiRecord(RespCenter, FieldNo(Code));
                            DefaultDimMultiple.RunModal;
                        end;
                    }
                }
            }
        }
    }

    procedure GetSelectionFilter(): Text
    var
        ResponsibilityCenter: Record "Responsibility Center";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(ResponsibilityCenter);
        exit(SelectionFilterManagement.GetSelectionFilterForResponsibilityCenter(ResponsibilityCenter));
    end;
}

