page 12417 "Customs Declaration Subform"
{
    Caption = 'Lines';
    PageType = ListPart;
    PopulateAllFields = true;
    SourceTable = "CD No. Information";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("CD No."; "CD No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customs declaration number.';
                }
                field("CD Header No."; "CD Header No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customs declaration. ';
                }
                field("Temporary CD No."; "Temporary CD No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field(Inventory; Inventory)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Purchases; Purchases)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item quantity of the posted purchase invoice associated with this line.';
                }
                field(Sales; Sales)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item quantity of the posted sales invoice associated with this line.';
                }
                field("Positive Adjmt."; "Positive Adjmt.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Negative Adjmt."; "Negative Adjmt.")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }

    [Scope('OnPrem')]
    procedure UpdateForm()
    begin
        CurrPage.Update;
    end;

    [Scope('OnPrem')]
    procedure Navigate()
    var
        Navigate: Page Navigate;
    begin
        Navigate.SetTracking('', '', "CD No.");
        Navigate.Run;
    end;
}

