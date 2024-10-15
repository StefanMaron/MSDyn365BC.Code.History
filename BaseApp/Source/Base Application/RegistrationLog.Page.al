page 11758 "Registration Log"
{
    Caption = 'Registration Log';
    DataCaptionFields = "Account Type", "Account No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Registration Log";
    SourceTableView = SORTING("Entry No.")
                      ORDER(Descending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the entry number that is assigned to the entry.';
                }
                field("Registration No."; "Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the registration number of customer or vendor.';
                }
                field("Account Type"; "Account Type")
                {
                    Editable = false;
                    ToolTip = 'Specifies typ of account';
                    Visible = false;
                }
                field("Account No."; "Account No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies No of account';
                    Visible = false;
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of issued payment order lines';
                }
                field("Verified Date"; "Verified Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date of verified.';
                }
                field("Verified Name"; "Verified Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of customer or vendor was verified.';
                }
                field("Verified Address"; "Verified Address")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the address of customer or vendor was verified.';
                }
                field("Verified City"; "Verified City")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the city of customer or vendor was verified.';
                }
                field("Verified Post Code"; "Verified Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the post code of customer or vendor was verified.';
                }
                field("Verified VAT Registration No."; "Verified VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the VAT registration number of customer or vendor was verified.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user associated with the entry.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Verified Result"; "Verified Result")
                {
                    ToolTip = 'Specifies verified result';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Verify Registration No.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Verify Registration No.';
                Image = Start;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Codeunit "Reg. Lookup Ext. Data Hndl";
                ToolTip = 'Verifies registration number';
            }
            action("Update Card")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Update Card';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Opens ares update page';

                trigger OnAction()
                begin
                    UpdateCard;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if FindFirst then;
    end;
}

