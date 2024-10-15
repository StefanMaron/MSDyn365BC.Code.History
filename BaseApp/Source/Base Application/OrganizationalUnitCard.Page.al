page 17379 "Organizational Unit Card"
{
    Caption = 'Organizational Unit Card';
    PageType = Card;
    SourceTable = "Organizational Unit";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code associated with the organizational unit.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name associated with the organizational unit.';
                }
                field("Full Name"; "Full Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Totalling; Totalling)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Parent Code"; "Parent Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Manager No."; "Manager No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the record.';
                }
            }
            group(Administration)
            {
                Caption = 'Administration';
                field("Isolated Org. Unit"; "Isolated Org. Unit")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Address Code"; "Address Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the address.';
                }
                field(Purpose; Purpose)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payment Type"; "Payment Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Timesheet Owner"; "Timesheet Owner")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(History)
            {
                Caption = 'History';
                field("Created by User"; "Created by User")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who created the record.';
                }
                field("Created Date"; "Created Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the record was created.';
                }
                field("Approved by User"; "Approved by User")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who approved the record. ';
                }
                field("Approval Date"; "Approval Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the record was approved.';
                }
                field("Closed by User"; "Closed by User")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who closed the record.';
                }
                field("Closed Date"; "Closed Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the record was closed.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("O&rg. Unit")
            {
                Caption = 'O&rg. Unit';
                action("Default Contract Terms")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Default Contract Terms';
                    Image = Default;
                    RunObject = Page "Default Labor Contract Terms";
                    RunPageLink = "Org. Unit Code" = FIELD(Code);
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Approve)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approve';
                    Image = Approve;
                    ShortCutKey = 'F9';

                    trigger OnAction()
                    begin
                        Approve(false);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen';
                    Image = ReOpen;
                    ToolTip = 'Open the closed or released record.';

                    trigger OnAction()
                    begin
                        Reopen(false);
                    end;
                }
                action(Close)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Close';
                    Image = Close;

                    trigger OnAction()
                    begin
                        Close(false);
                    end;
                }
            }
        }
    }
}

