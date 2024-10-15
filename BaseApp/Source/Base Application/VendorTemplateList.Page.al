page 11794 "Vendor Template List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Templates';
    CardPageID = "Vendor Template Card CZ";
    Editable = false;
    PageType = List;
    SourceTable = "Vendor Template";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1220012)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor template code.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor template description.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code.';
                }
                field("Territory Code"; "Territory Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the territory code for the vendor.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220005; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220004; Notes)
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
            group("&Vendor Template")
            {
                Caption = '&Vendor Template';
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = CONST(11794),
                                      "No." = FIELD(Code);
                        ShortCutKey = 'Shift+Ctrl+D';
                        ToolTip = 'View or edit the dimension sets that are set up for the vendor teplate.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        ToolTip = 'Show how a group of vendor template use dimensions and dimension values.';

                        trigger OnAction()
                        var
                            VendTemplate: Record "Vendor Template";
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(VendTemplate);
                            DefaultDimMultiple.SetMultiVendTemplate(VendTemplate);
                            DefaultDimMultiple.RunModal;
                        end;
                    }
                }
            }
        }
    }
}

