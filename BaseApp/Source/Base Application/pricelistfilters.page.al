page 7013 "Price List Filters"
{
    Caption = 'Price List Filters';
    PageType = Document;
    SourceTable = "Price List Header";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = EditablePage;
                group(Source)
                {
                    ShowCaption = false;
                    field(CustomerSourceType; CustomerSourceType)
                    {
                        Caption = 'Assign-to Type';
                        ApplicationArea = All;
                        Importance = Promoted;
                        Visible = IsCustomerGroup;
                        ToolTip = 'Specifies the type of entity to which the price list is assigned. The options are relevant to the entity you are currently viewing.';

                        trigger OnValidate()
                        begin
                            ValidateSourceType(CustomerSourceType.AsInteger());
                        end;
                    }
                    field(VendorSourceType; VendorSourceType)
                    {
                        Caption = 'Assign-to Type';
                        ApplicationArea = All;
                        Importance = Promoted;
                        Visible = IsVendorGroup;
                        ToolTip = 'Specifies the type of entity to which the price list is assigned. The options are relevant to the entity you are currently viewing.';

                        trigger OnValidate()
                        begin
                            ValidateSourceType(VendorSourceType.AsInteger());
                        end;
                    }
                    field(JobSourceType; JobSourceType)
                    {
                        Caption = 'Assign-to Type';
                        ApplicationArea = All;
                        Importance = Promoted;
                        Visible = IsJobGroup;
                        ToolTip = 'Specifies the type of entity to which the price list is assigned. The options are relevant to the entity you are currently viewing.';

                        trigger OnValidate()
                        begin
                            ValidateSourceType(JobSourceType.AsInteger());
                        end;
                    }
                    field(SourceNo; Rec."Source No.")
                    {
                        ApplicationArea = All;
                        Importance = Promoted;
                        Enabled = SourceNoEnabled;
                        ToolTip = 'Specifies the entity to which the prices are assigned. The options depend on the selection in the Assign-to Type field. If you choose an entity, the price list will be used only for that entity.';
                    }
                }
                field(CurrencyCode; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency code of the price list.';
                }
                group(Dates)
                {
                    ShowCaption = false;
                    field(StartingDate; Rec."Starting Date")
                    {
                        ApplicationArea = All;
                        Importance = Promoted;
                        ToolTip = 'Specifies the date from which the price is valid.';
                    }
                    field(EndingDate; Rec."Ending Date")
                    {
                        ApplicationArea = All;
                        Importance = Promoted;
                        ToolTip = 'Specifies the last date that the price is valid.';
                    }
                }
                field(AmountType; Rec."Amount Type")
                {
                    ApplicationArea = All;
                    Caption = 'Defines';
                    ToolTip = 'Specifies the amount type filter that defines the columns shown in the price list lines.';
                }
                group(Tax)
                {
                    Caption = 'VAT';
                    field(VATBusPostingGrPrice; Rec."VAT Bus. Posting Gr. (Price)")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        ToolTip = 'Specifies the default VAT business posting group code.';
                    }
                    field(PriceIncludesVAT; Rec."Price Includes VAT")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        ToolTip = 'Specifies the if prices include VAT.';
                    }
                }
                group(LineDefaults)
                {
                    Caption = 'Line Defaults';
                    field(AllowInvoiceDisc; Rec."Allow Invoice Disc.")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        ToolTip = 'Specifies whether invoice discount is allowed. You can change this value on the lines.';
                    }
                    field(AllowLineDisc; Rec."Allow Line Disc.")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        ToolTip = 'Specifies whether line discounts are allowed. You can change this value on the lines.';
                    }
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Validate("Source Type");
        SourceNoEnabled := Rec.IsSourceNoAllowed();
        UpdateSourceType();
    end;

    local procedure UpdateSourceType()
    begin
        case Rec."Source Group" of
            Rec."Source Group"::Customer:
                CustomerSourceType := Enum::"Sales Price Source Type".FromInteger(Rec."Source Type".AsInteger());
            Rec."Source Group"::Vendor:
                VendorSourceType := Enum::"Purchase Price Source Type".FromInteger(Rec."Source Type".AsInteger());
            Rec."Source Group"::Job:
                JobSourceType := Enum::"Job Price Source Type".FromInteger(Rec."Source Type".AsInteger());
        end;
        IsCustomerGroup := Rec."Source Group" = Rec."Source Group"::Customer;
        IsVendorGroup := Rec."Source Group" = Rec."Source Group"::Vendor;
        IsJobGroup := Rec."Source Group" = Rec."Source Group"::Job;
    end;

    var
        JobSourceType: Enum "Job Price Source Type";
        CustomerSourceType: Enum "Sales Price Source Type";
        VendorSourceType: Enum "Purchase Price Source Type";
        IsCustomerGroup: Boolean;
        IsVendorGroup: Boolean;
        IsJobGroup: Boolean;
        SourceNoEnabled: Boolean;
        EditablePage: Boolean;

    procedure Set(PriceListHeader: Record "Price List Header")
    begin
        Rec := PriceListHeader;
        Rec.Insert();
        EditablePage := Rec."Allow Updating Defaults";
    end;

    local procedure ValidateSourceType(SourceType: Integer)
    begin
        Rec.Validate("Source Type", SourceType);
        SourceNoEnabled := Rec.IsSourceNoAllowed();
        CurrPage.SaveRecord();
    end;
}
