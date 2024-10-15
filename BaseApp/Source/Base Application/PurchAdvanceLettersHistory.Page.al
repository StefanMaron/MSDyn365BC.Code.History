#if not CLEAN19
page 31026 "Purch. Advance Letters History"
{
    Caption = 'Purch. Advance Letters History (Obsolete)';
    Editable = true;
    PageType = ListPlus;
    SaveValues = true;
    SourceTable = Vendor;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            field(CurrentMenuTypeValue; CurrentMenuType)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies current menu type';
                Visible = false;
            }
            group(Control1220007)
            {
                ShowCaption = false;
                field(OpenBtn; CurrentMenuTypeOpt)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status';
                    OptionCaption = 'Open,Pending Advance Payment,Pending Advance Invoice,Pending Final Invoice,Closed';
                    ToolTip = 'Specifies the status of the purchase advance letters.';

                    trigger OnValidate()
                    begin
                        if CurrentMenuTypeOpt = CurrentMenuTypeOpt::x5 then
                            x5CurrentMenuTypeOptOnValidate();
                        if CurrentMenuTypeOpt = CurrentMenuTypeOpt::x4 then
                            x4CurrentMenuTypeOptOnValidate();
                        if CurrentMenuTypeOpt = CurrentMenuTypeOpt::x3 then
                            x3CurrentMenuTypeOptOnValidate();
                        if CurrentMenuTypeOpt = CurrentMenuTypeOpt::x2 then
                            x2CurrentMenuTypeOptOnValidate();
                        if CurrentMenuTypeOpt = CurrentMenuTypeOpt::x1 then
                            x1CurrentMenuTypeOptOnValidate();
                    end;
                }
                field("STRSUBSTNO(Text001Lbl,QtyOfDocs[1])"; StrSubstNo(Text001Lbl, QtyOfDocs[1]))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open';
                    Editable = false;
                    ToolTip = 'Specifies the number of opened sales advance letters of the vendor.';
                }
                field("STRSUBSTNO(Text001Lbl,QtyOfDocs[2])"; StrSubstNo(Text001Lbl, QtyOfDocs[2]))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pending Advance';
                    Editable = false;
                    ToolTip = 'Specifies the number of pending advance letters of the vendor.';
                }
                field("STRSUBSTNO(Text001Lbl,QtyOfDocs[3])"; StrSubstNo(Text001Lbl, QtyOfDocs[3]))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pending Adv. Invoice';
                    Editable = false;
                    ToolTip = 'Specifies the number of pending advance invoice of the vendor.';
                }
                field("STRSUBSTNO(Text001Lbl,QtyOfDocs[4])"; StrSubstNo(Text001Lbl, QtyOfDocs[4]))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pending Final Invoice';
                    Editable = false;
                    ToolTip = 'Specifies the number of pending final invoice of the vendor.';
                }
                field("STRSUBSTNO(Text001Lbl,QtyOfDocs[5])"; StrSubstNo(Text001Lbl, QtyOfDocs[5]))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Closed';
                    Editable = false;
                    ToolTip = 'Specifies the number of closed sales advance letters of the vendor.';
                }
            }
            part(SubForm; "P.Adv. Letters History Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Pay-to Vendor No." = FIELD("No.");
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CurrentMenuTypeOpt := CurrentMenuType;
    end;

    trigger OnOpenPage()
    begin
        CurrentMenuType := 0;
        ChangeSubMenu(1);
    end;

    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        PurchPostAdvances: Codeunit "Purchase-Post Advances";
        QtyOfDocs: array[5] of Integer;
        CurrentMenuType: Integer;
        CurrentMenuTypeOpt: Option x1,x2,x3,x4,x5;
        Text001Lbl: Label '(%1)', Locked = true;

    [Scope('OnPrem')]
    procedure ChangeSubMenu(NewMenuType: Integer)
    begin
        if CurrentMenuType <> NewMenuType then begin
            CurrentMenuType := NewMenuType;
            PurchPostAdvances.CalcNoOfDocs("No.", QtyOfDocs);

            PurchAdvanceLetterLine.SetRange("Pay-to Vendor No.", "No.");
            PurchAdvanceLetterLine.SetRange(Status, CurrentMenuType - 1);
            CurrPage.SubForm.PAGE.SetTableView(PurchAdvanceLetterLine);
            CurrPage.SubForm.PAGE.SetCurrSubPageUpdate();
        end;
    end;

    local procedure x1CurrentMenuTypeOptOnPush()
    begin
        ChangeSubMenu(1);
    end;

    local procedure x1CurrentMenuTypeOptOnValidate()
    begin
        x1CurrentMenuTypeOptOnPush();
    end;

    local procedure x2CurrentMenuTypeOptOnPush()
    begin
        ChangeSubMenu(2);
    end;

    local procedure x2CurrentMenuTypeOptOnValidate()
    begin
        x2CurrentMenuTypeOptOnPush();
    end;

    local procedure x3CurrentMenuTypeOptOnPush()
    begin
        ChangeSubMenu(3);
    end;

    local procedure x3CurrentMenuTypeOptOnValidate()
    begin
        x3CurrentMenuTypeOptOnPush();
    end;

    local procedure x4CurrentMenuTypeOptOnPush()
    begin
        ChangeSubMenu(4);
    end;

    local procedure x4CurrentMenuTypeOptOnValidate()
    begin
        x4CurrentMenuTypeOptOnPush();
    end;

    local procedure x5CurrentMenuTypeOptOnPush()
    begin
        ChangeSubMenu(5);
    end;

    local procedure x5CurrentMenuTypeOptOnValidate()
    begin
        x5CurrentMenuTypeOptOnPush();
    end;
}
#endif
