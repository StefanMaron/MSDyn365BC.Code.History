page 2314 "BC O365 Item List"
{
    Caption = 'Prices';
    CardPageID = "BC O365 Item Card";
    DataCaptionExpression = Description;
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = Item;
    SourceTableView = SORTING(Description);

    layout
    {
        area(content)
        {
            repeater(Item)
            {
                Caption = 'Price';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Enabled = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies what you are selling.';
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = '2';
                    AutoFormatType = 10;
                    Caption = 'Price';
                    ToolTip = 'Specifies the price for one unit.';
                }
                field("<Unit Price>"; UnitOfMeasureDescription)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Price per';
                    QuickEntry = false;
                    ToolTip = 'Specifies the price for one unit.';
                }
                field("Base Unit of Measure"; "Base Unit of Measure")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Enabled = false;
                    ToolTip = 'Specifies the unit in which the item is held in inventory. The base unit of measure also serves as the conversion basis for alternate units of measure.';
                    Visible = false;
                }
                field("Tax Group Code"; "Tax Group Code")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Tax Group';
                    NotBlank = true;
                    ToolTip = 'Specifies the tax group code for the tax-detail entry.';
                    Visible = NOT IsUsingVAT;
                }
                field(VATProductPostingGroupDescription; VATProductPostingGroupDescription)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'VAT';
                    NotBlank = true;
                    QuickEntry = false;
                    ToolTip = 'Specifies the VAT rate for this price.';
                    Visible = IsUsingVAT;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Edit)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Edit';
                RunObject = Page "BC O365 Item Card";
                RunPageOnRec = true;
                ShortCutKey = 'Return';
                ToolTip = 'Opens the Price.';
                Visible = false;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if VATProductPostingGroup.Get("VAT Prod. Posting Group") then
            VATProductPostingGroupDescription := VATProductPostingGroup.Description;
        if UnitOfMeasure.Get("Base Unit of Measure") then
            UnitOfMeasureDescription := UnitOfMeasure.GetDescriptionInCurrentLanguage;
    end;

    trigger OnInit()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        IsUsingVAT := O365SalesInitialSetup.IsUsingVAT;
    end;

    var
        VATProductPostingGroupDescription: Text[100];
        IsUsingVAT: Boolean;
        UnitOfMeasureDescription: Text[50];
}

