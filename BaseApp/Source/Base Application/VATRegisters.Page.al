page 12151 "VAT Registers"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Register';
    PageType = List;
    SourceTable = "VAT Register";
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
                    ApplicationArea = All;
                    ToolTip = 'Specifies a VAT Register code.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the VAT register.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the origin of the VAT register.';
                }
                field("Last Printing Date"; "Last Printing Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the VAT register report was last printed.';
                }
                field("Last Printed VAT Register Page"; "Last Printed VAT Register Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last printed page of the VAT register report.';
                }
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
                action("Change Reprinting Information")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Change Reprinting Information';
                    Image = ReverseRegister;
                    RunObject = Page "VAT Register Reprinting Info.";
                    RunPageLink = "Vat Register Code" = FIELD(Code);
                    ToolTip = 'Update the reprinting information.';
                }
            }
        }
    }
}

