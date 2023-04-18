#if not CLEAN21
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
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Item)
            {
                Caption = 'Price';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Enabled = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies what you are selling.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = '2';
                    AutoFormatType = 10;
                    Caption = 'Price';
                    ToolTip = 'Specifies the price for one unit.';
                }
                field("<Unit Price>"; UnitOfMeasureDescription)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Price per';
                    QuickEntry = false;
                    ToolTip = 'Specifies the price for one unit.';
                }
                field("Base Unit of Measure"; Rec."Base Unit of Measure")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Enabled = false;
                    ToolTip = 'Specifies the unit in which the item is held in inventory. The base unit of measure also serves as the conversion basis for alternate units of measure.';
                    Visible = false;
                }
                field("Tax Group Code"; Rec."Tax Group Code")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Tax Group';
                    NotBlank = true;
                    ToolTip = 'Specifies the tax group code for the tax-detail entry.';
                    Visible = NOT IsUsingVAT;
                }
                field(VATProductPostingGroupDescription; VATProductPostingGroupDescription)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
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
            UnitOfMeasureDescription := UnitOfMeasure.GetDescriptionInCurrentLanguage();
    end;

    trigger OnInit()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        IsUsingVAT := O365SalesInitialSetup.IsUsingVAT();
    end;

    var
        VATProductPostingGroupDescription: Text[100];
        IsUsingVAT: Boolean;
        UnitOfMeasureDescription: Text[50];
}
#endif
