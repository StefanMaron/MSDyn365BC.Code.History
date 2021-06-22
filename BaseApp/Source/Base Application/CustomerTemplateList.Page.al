page 5156 "Customer Template List"
{
    AdditionalSearchTerms = 'convert contact, new customer';
    ApplicationArea = RelationshipMgmt;
    Caption = 'Contact Conversion Templates';
    CardPageID = "Customer Template Card";
    Editable = false;
    PageType = List;
    SourceTable = "Customer Template";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the contact conversion template. You can set up as many codes as you want. The code must be unique. You cannot have the same code twice in one table.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the contact conversion template.';
                }
                field("Contact Type"; "Contact Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the contact type of the contact conversion template.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the country/region of the customer that will be created with the template.';
                }
                field("Territory Code"; "Territory Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the territory code of the customer that will be created with the template.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code of the customer that will be created with the template.';
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
            group("&Contact Conversion Template")
            {
                Caption = '&Contact Conversion Template';
                Image = Template;
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
                        RunPageLink = "Table ID" = CONST(5105),
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
                            CustTemplate: Record "Customer Template";
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(CustTemplate);
                            DefaultDimMultiple.SetMultiRecord(CustTemplate, FieldNo(Code));
                            DefaultDimMultiple.RunModal;
                        end;
                    }
                }
            }
        }
    }
}

