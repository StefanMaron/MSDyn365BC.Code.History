page 2183 "O365 Sales Invoice Line Dummy"
{
    Caption = 'Invoice Line';
    DeleteAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = "Sales Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    LookupPageID = "O365 Sales Item Lookup";
                    ShowCaption = false;
                    ToolTip = 'Specifies a description of the item or service on the line.';

                    trigger OnAfterLookup(Selected: RecordRef)
                    var
                        GLAccount: record "G/L Account";
                        Item: record Item;
                        Resource: record Resource;
                        FixedAsset: record "Fixed Asset";
                        ItemCharge: record "Item Charge";
                    begin
                        case Rec.Type of
                            Rec.Type::Item:
                                begin
                                    Selected.SetTable(Item);
                                    Validate("No.", Item."No.");
                                end;
                            Rec.Type::"G/L Account":
                                begin
                                    Selected.SetTable(GLAccount);
                                    Validate("No.", GLAccount."No.");
                                end;
                            Rec.Type::Resource:
                                begin
                                    Selected.SetTable(Resource);
                                    Validate("No.", Resource."No.");
                                end;
                            Rec.Type::"Fixed Asset":
                                begin
                                    Selected.SetTable(FixedAsset);
                                    Validate("No.", FixedAsset."No.");
                                end;
                            Rec.Type::"Charge (Item)":
                                begin
                                    Selected.SetTable(ItemCharge);
                                    Validate("No.", ItemCharge."No.");
                                end;
                        end;
                    end;

                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Line Amount';
                    Editable = false;
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
                field("Price description"; "Price description")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                }
                field(LineAmountExclVAT; GetLineAmountExclVAT)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Line Amount';
                    Editable = false;
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
                field(LineAmountInclVAT; GetLineAmountInclVAT)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Line Amount Incl. VAT';
                    Editable = false;
                    ToolTip = 'Specifies the net amount, including VAT and excluding any invoice discount, that must be paid for products on the line.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(AllItems)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Add multiple';
                Ellipsis = true;
                Image = List;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Select items from the full item list';
                Visible = false;

                trigger OnAction()
                begin
                    SelectFromFullItemList;
                end;
            }
            action(DeleteLine)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Delete Line';
                Gesture = RightSwipe;
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                Scope = Repeater;
                ToolTip = 'Delete the selected line.';

                trigger OnAction()
                var
                    EnvInfoProxy: Codeunit "Env. Info Proxy";
                begin
                    if "No." = '' then
                        exit;

                    if not Confirm(DeleteQst, true) then
                        exit;
                    Delete(true);
                    if not EnvInfoProxy.IsInvoicing then
                        CurrPage.Update();
                end;
            }
            action(Open)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Open';
                Image = DocumentEdit;
                RunObject = Page "O365 Sales Invoice Line Card";
                RunPageOnRec = true;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
                Visible = false;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ConstructCurrencyFormatString;
    end;

    trigger OnInit()
    begin
        Currency.InitRoundingPrecision;
        ConstructCurrencyFormatString;
    end;

    var
        Currency: Record Currency;
        CurrencyFormat: Text;
        DeleteQst: Label 'Are you sure?';

    local procedure ConstructCurrencyFormatString()
    var
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        CurrencySymbol: Text[10];
    begin
        if "Currency Code" = '' then begin
            GLSetup.Get();
            CurrencySymbol := GLSetup.GetCurrencySymbol;
        end else begin
            if Currency.Get("Currency Code") then;
            CurrencySymbol := Currency.GetCurrencySymbol;
        end;
        CurrencyFormat := StrSubstNo('%1<precision, 2:2><standard format, 0>', CurrencySymbol);
    end;

    procedure SelectFromFullItemList()
    var
        O365ItemBasketPart: Page "O365 Item Basket Part";
    begin
        O365ItemBasketPart.SetSalesLines(Rec);
        O365ItemBasketPart.Run();
    end;
}

