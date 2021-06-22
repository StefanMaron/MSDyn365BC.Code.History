page 180 "Additional Cust. Terms Setup"
{
    Caption = 'Additional Customer Terms Setup Card';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "License Agreement";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Accepted; Accepted)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the license agreement was accepted.';
                }
                field("Accepted By"; "Accepted By")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the person that accepted the license agreement.';
                }
                field("Accepted On"; "Accepted On")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date the license agreement is accepted.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Activate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Activate';
                Enabled = NOT Active;
                Image = Agreement;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Activate the current customer terms setup.';

                trigger OnAction()
                begin
                    Validate("Effective Date", Today);
                    Modify
                end;
            }
            action(Deactivate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Deactivate';
                Enabled = Active;
                Image = Stop;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Deactivate the current customer terms setup.';

                trigger OnAction()
                begin
                    Validate("Effective Date", 0D);
                    Modify
                end;
            }
            action(Reset)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reset';
                Enabled = Active;
                Image = ResetStatus;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Reset the current customer terms setup.';

                trigger OnAction()
                begin
                    Validate(Accepted, false);
                    Modify
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Active := GetActive
    end;

    trigger OnOpenPage()
    begin
        if not Get then
            Insert
    end;

    var
        Active: Boolean;
}

