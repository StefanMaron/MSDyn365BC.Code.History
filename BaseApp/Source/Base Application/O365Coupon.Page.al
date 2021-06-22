page 2165 "O365 Coupon"
{
    Caption = 'Coupon';
    DeleteAllowed = false;
    Editable = false;
    PageType = Card;
    SourceTable = "O365 Coupon Claim";

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                }
                field("Status Text"; "Status Text")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    StyleExpr = StatusStyleExpr;
                }
                group(Control8)
                {
                    ShowCaption = false;
                    field(OfferText; OfferText)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Offer';
                        MultiLine = true;
                    }
                }
                group(Control12)
                {
                    ShowCaption = false;
                    field(TermsText; TermsText)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Terms';
                        MultiLine = true;
                    }
                }
                group(Control3)
                {
                    ShowCaption = false;
                    Visible = "Discount Value" <> 0;
                    field("Amount Text"; "Amount Text")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        ToolTip = 'Specifies the coupon amount in words.';
                    }
                    field(Expiration; Expiration)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Expiration';
                    }
                    group(Control20)
                    {
                        ShowCaption = false;
                        Visible = ExpiresInDays >= 0;
                        field(ExpiresInDays; ExpiresInDays)
                        {
                            ApplicationArea = Basic, Suite, Invoicing;
                            Caption = 'Days until expiration';
                            ToolTip = 'Specifies the number of days until this coupon expires.';
                        }
                    }
                }
                group(Control16)
                {
                    ShowCaption = false;
                    Visible = ("Discount Value" = 0) AND (ExpiresInDays >= 0);
                    field(ExpirationDate2; Expiration)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Expiration';
                    }
                    field(ExpirationInDays2; ExpiresInDays)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Days until expiration';
                        ToolTip = 'Specifies the number of days until this coupon expires.';
                    }
                }
                group(Control22)
                {
                    ShowCaption = false;
                    Visible = ("Discount Value" = 0) AND (ExpiresInDays < 0);
                    field(ExpirationDate3; Expiration)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Expiration';
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(UseCoupon)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Use coupon';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Use this coupon on the current invoice.';
                Visible = NOT "Is applied";

                trigger OnAction()
                begin
                    ApplyCoupon;
                end;
            }
            action(DoNotUseCoupon)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Do not use coupon';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Do not use this coupon on the current invoice.';
                Visible = "Is applied";

                trigger OnAction()
                begin
                    if Unapply then
                        CurrPage.Close;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ExpiresInDays := Expiration - WorkDate;
        UpdateStatusText;
        CalcFields("Is applied");
        OfferText := GetOffer;
        TermsText := GetTerms;
        if ExpiresInDays < 0 then
            StatusStyleExpr := 'Unfavorable';
        if "Is applied" then
            StatusStyleExpr := 'Favorable';
    end;

    var
        ExpiresInDays: Integer;
        OfferText: Text;
        TermsText: Text;
        StatusStyleExpr: Text;

    procedure ApplyCoupon()
    begin
        if Apply then
            CurrPage.Close;
    end;
}

