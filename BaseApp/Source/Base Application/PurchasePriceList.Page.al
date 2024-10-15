page 7018 "Purchase Price List"
{
    Caption = 'Purchase Price List';
    PageType = ListPlus;
    PromotedActionCategories = 'New,Process,Report,Navigate';
    RefreshOnActivate = true;
    SourceTable = "Price List Header";
    SourceTableView = WHERE("Price Type" = CONST(Purchase));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the unique identifier of the price list.';
                    Editable = PriceListIsEditable;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEditCode(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ShowMandatory = true;
                    Editable = PriceListIsEditable;
                    ToolTip = 'Specifies the description of the price list.';
                }
                field(SourceType; VendorSourceType)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Applies-to Type';
                    Editable = PriceListIsEditable;
                    Visible = IsVendorGroup;
                    ToolTip = 'Specifies the source of the price on the price list line. For example, the price can come from the vendor.';

                    trigger OnValidate()
                    begin
                        ValidateSourceType(VendorSourceType.AsInteger());
                    end;
                }
                field(JobSourceType; JobSourceType)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Applies-to Type';
                    Editable = PriceListIsEditable;
                    Visible = IsJobGroup;
                    ToolTip = 'Specifies the source of the price on the price list line. For example, the price can come from the job or job task.';

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
                    Editable = PriceListIsEditable;
                    ToolTip = 'Specifies the unique identifier of the source of the price on the price list line.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                group(Tax)
                {
                    Caption = 'Tax';
                    field(PriceIncludesVAT; Rec."Price Includes VAT")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        Editable = PriceListIsEditable;
                        ToolTip = 'Specifies the if prices include VAT.';
                    }
                }
                group(View)
                {
                    Caption = 'View';
                    Visible = ViewGroupIsVisible;
                    field(AmountType; ViewAmountType)
                    {
                        ApplicationArea = All;
                        Caption = 'View Columns for';
                        ToolTip = 'Specifies the amount type filter that defines the columns shown in the price list lines.';
                        trigger OnValidate()
                        begin
                            CurrPage.Lines.Page.SetSubFormLinkFilter(ViewAmountType);
                        end;
                    }
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Specifies whether the price list is in Draft status and can be edited, Inactive and cannot be edited or used, or Active and used for price calculations.';

                    trigger OnValidate()
                    begin
                        PriceListIsEditable := Rec.IsEditable();
                    end;
                }
                field(CurrencyCode; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Editable = PriceListIsEditable;
                    ToolTip = 'Specifies the currency code of the price list.';
                }
                field(StartingDate; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Editable = PriceListIsEditable;
                    ToolTip = 'Specifies the date from which the price is valid.';
                }
                field(EndingDate; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Editable = PriceListIsEditable;
                    ToolTip = 'Specifies the last date that the price is valid.';
                }
                group(LineDefaults)
                {
                    Caption = 'Line Defaults';
                    field(AllowUpdatingDefaults; Rec."Allow Updating Defaults")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        Editable = PriceListIsEditable;
                        ToolTip = 'Specifies whether users can change the values in the fields on the price list line that contain default values from the header.';
                        trigger OnValidate()
                        begin
                            CurrPage.Lines.Page.SetHeader(Rec);
                        end;
                    }
                    field(AllowLineDisc; Rec."Allow Line Disc.")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        Editable = PriceListIsEditable;
                        ToolTip = 'Specifies whether line discounts are allowed. You can change this value on the lines.';
                    }
                }
            }
            part(Lines; "Purchase Price List Lines")
            {
                ApplicationArea = Basic, Suite;
                Editable = PriceListIsEditable;
                SubPageLink = "Price List Code" = FIELD(Code);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SuggestLines)
            {
                ApplicationArea = Basic, Suite;
                Enabled = PriceListIsEditable;
                Ellipsis = true;
                Image = SuggestItemPrice;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Suggest Lines';
                ToolTip = 'Creates the purchase price list lines based on the unit cost in the product cards, like item or resource. Change the price list status to ''Draft'' to run this action.';

                trigger OnAction()
                var
                    PriceListManagement: Codeunit "Price List Management";
                begin
                    PriceListManagement.AddLines(Rec);
                end;
            }
            action(CopyLines)
            {
                ApplicationArea = Basic, Suite;
                Enabled = PriceListIsEditable;
                Ellipsis = true;
                Image = CopyWorksheet;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Copy Lines';
                ToolTip = 'Copies the lines from the existing price list. New prices can be adjusted by a factor and rounded differently. Change the price list status to ''Draft'' to run this action.';

                trigger OnAction()
                var
                    PriceListManagement: Codeunit "Price List Management";
                begin
                    PriceListManagement.CopyLines(Rec);
                end;
            }
        }
    }

    trigger OnInit()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        PriceCalculationMgt.TestIsEnabled();
    end;

    trigger OnOpenPage()
    begin
        UpdateSourceType();
        PriceUXManagement.GetFirstSourceFromFilter(Rec, OriginalPriceSource, DefaultSourceType);
        SetSourceNoEnabled();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        PriceListIsEditable := Rec.IsEditable();
        UpdateSourceType();
        ViewAmountType := Rec."Amount Type";
        if ViewAmountType = ViewAmountType::Any then
            ViewGroupIsVisible := true
        else
            ViewGroupIsVisible := not PriceUXManagement.IsAmountTypeFiltered(Rec);

        CurrPage.Lines.Page.SetHeader(Rec);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        DefaultAmountType: Enum "Price Amount Type";
    begin
        Rec.CopyFrom(OriginalPriceSource);
        UpdateSourceType();
        if PriceUXManagement.IsAmountTypeFiltered(Rec, DefaultAmountType) then
            Rec."Amount Type" := DefaultAmountType;
        SetSourceNoEnabled();
    end;

    trigger OnClosePage()
    begin
        if Rec.Code <> '' then
            Rec.UpdateAmountType();
    end;

    local procedure UpdateSourceType()
    begin
        case Rec."Source Group" of
            Rec."Source Group"::Vendor:
                begin
                    IsVendorGroup := true;
                    VendorSourceType := "Purchase Price Source Type".FromInteger(Rec."Source Type".AsInteger());
                    DefaultSourceType := Rec."Source Type"::"All Vendors";
                end;
            Rec."Source Group"::Job:
                begin
                    IsJobGroup := true;
                    JobSourceType := "Job Price Source Type".FromInteger(Rec."Source Type".AsInteger());
                    DefaultSourceType := Rec."Source Type"::"All Jobs";
                end;
        end;
    end;

    var
        OriginalPriceSource: Record "Price Source";
        PriceUXManagement: Codeunit "Price UX Management";
        DefaultSourceType: Enum "Price Source Type";
        JobSourceType: Enum "Job Price Source Type";
        VendorSourceType: Enum "Purchase Price Source Type";
        ViewAmountType: Enum "Price Amount Type";
        IsVendorGroup: Boolean;
        IsJobGroup: Boolean;
        SourceNoEnabled: Boolean;
        PriceListIsEditable: Boolean;
        ViewGroupIsVisible: Boolean;

    local procedure SetSourceNoEnabled()
    begin
        SourceNoEnabled := Rec.IsSourceNoAllowed();
    end;

    local procedure ValidateSourceType(SourceType: Integer)
    begin
        Rec.Validate("Source Type", SourceType);
        SetSourceNoEnabled();
        CurrPage.SaveRecord();
    end;
}
