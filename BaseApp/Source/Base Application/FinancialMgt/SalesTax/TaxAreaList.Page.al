namespace Microsoft.Finance.SalesTax;

page 469 "Tax Area List"
{
    ApplicationArea = SalesTax;
    Caption = 'Tax Areas';
    CardPageID = "Tax Area";
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Tax Area";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code you want to assign to this tax area. You can enter up to 20 characters, both numbers and letters. It is a good idea to enter a code that is easy to remember.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies a description of the tax area. If you use a number as the tax code, you might want to describe the tax area in this field.';
                }
                field("Country/Region"; Rec."Country/Region")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the country/region of this tax area. Tax jurisdictions of the same country/region can only then be assigned to this tax area.';
                }
                field("Use External Tax Engine"; Rec."Use External Tax Engine")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies that you have purchased an external, third party sales tax engine, which calculates the sales tax rather than using the standard sales tax engine included in the product. Select the check box if this tax area code will indicate to the product that this external sales tax engine is to be used when this tax area code is used. Clear the check box to indicate that the standard, internal sales tax engine is to be used when this tax area code is used.';
                }
                field("Round Tax"; Rec."Round Tax")
                {
                    ToolTip = 'Specifies a rounding option for the tax area. This value is used to round United States sales tax to the nearest decimal. If a rounding value is selected, this value is used in the Sales Tax Amount Line table.';
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
    }
}

