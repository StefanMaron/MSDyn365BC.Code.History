#if not CLEAN21
page 2166 "O365 Coupon List"
{
    Caption = 'Coupons';
    Editable = false;
    PageType = List;
    SourceTable = "O365 Coupon Claim";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    StyleExpr = CodeStyleExpr;
                }
                field("Status Text"; Rec."Status Text")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    StyleExpr = StatusTextStyleExpr;
                }
                field("Amount Text"; Rec."Amount Text")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the coupon amount in letters.';
                }
                field(Offer; Rec.Offer)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'View';
                Image = ViewDetails;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
                Visible = false;

                trigger OnAction()
                var
                    IsAppliedBeforeOpening: Boolean;
                begin
                    IsAppliedBeforeOpening := Rec."Is applied";
                    PAGE.RunModal(PAGE::"O365 Coupon", Rec);
                    Rec.CalcFields("Is applied");
                    if (not IsAppliedBeforeOpening) and Rec."Is applied" then
                        CurrPage.Close();
                end;
            }
            action(UseCoupon)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Use coupon';
                Gesture = LeftSwipe;
                Scope = Repeater;
                ToolTip = 'Use this coupon.';

                trigger OnAction()
                begin
                    Rec.Apply();
                end;
            }
            action(DoNotUseCoupon)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Do not use coupon';
                Gesture = RightSwipe;
                Scope = Repeater;
                ToolTip = 'Do not use this coupon.';

                trigger OnAction()
                begin
                    Rec.Unapply();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(UseCoupon_Promoted; UseCoupon)
                {
                }
                actionref(DoNotUseCoupon_Promoted; DoNotUseCoupon)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.UpdateStatusText();
        if Rec."Is applied" then begin
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
#endif
