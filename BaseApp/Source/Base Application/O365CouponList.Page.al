page 2166 "O365 Coupon List"
{
    Caption = 'Coupons';
    Editable = false;
    PageType = List;
    SourceTable = "O365 Coupon Claim";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    StyleExpr = CodeStyleExpr;
                }
                field("Status Text"; "Status Text")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    StyleExpr = StatusTextStyleExpr;
                }
                field("Amount Text"; "Amount Text")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the coupon amount in letters.';
                }
                field(Offer; Offer)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ViewCoupon)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'View';
                Image = ViewDetails;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
                Visible = false;

                trigger OnAction()
                var
                    IsAppliedBeforeOpening: Boolean;
                begin
                    IsAppliedBeforeOpening := "Is applied";
                    PAGE.RunModal(PAGE::"O365 Coupon", Rec);
                    CalcFields("Is applied");
                    if (not IsAppliedBeforeOpening) and "Is applied" then
                        CurrPage.Close;
                end;
            }
            action(UseCoupon)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Use coupon';
                Gesture = LeftSwipe;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Scope = Repeater;
                ToolTip = 'Use this coupon.';

                trigger OnAction()
                begin
                    Apply;
                end;
            }
            action(DoNotUseCoupon)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Do not use coupon';
                Gesture = RightSwipe;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Scope = Repeater;
                ToolTip = 'Do not use this coupon.';

                trigger OnAction()
                begin
                    Unapply;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateStatusText;
        if "Is applied" then begin
            StatusTextStyleExpr := 'Favorable';
            CodeStyleExpr := 'Subordinate';
        end else begin
            Clear(StatusTextStyleExpr);
            Clear(CodeStyleExpr);
        end;
    end;

    var
        StatusTextStyleExpr: Text;
        CodeStyleExpr: Text;
}

