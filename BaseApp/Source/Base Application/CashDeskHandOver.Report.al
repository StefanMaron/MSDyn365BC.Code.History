report 11743 "Cash Desk Hand Over"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CashDeskHandOver.rdlc';
    Caption = 'Cash Desk Hand Over (Obsolete)';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
            column(CashDesk_No; CashDesk."No.")
            {
            }
            column(CashDesk_Name; CashDesk.Name)
            {
            }
            column(CashDesk_Responsibility_ID_Release; CashDesk."Responsibility ID (Release)")
            {
            }
            column(CashDesk_Responsibility_ID_Post; CashDesk."Responsibility ID (Post)")
            {
            }
            column(System_CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(System_ReportId; CurrReport.ObjectId(false))
            {
            }
            column(System_Today; Today)
            {
            }
            column(System_Time; Time)
            {
            }
            column(Variable_Balance; Balance)
            {
            }
            column(Variable_CurrCode; CurrCode)
            {
            }
            column(Variable_NewRespID; NewRespID)
            {
            }
            column(Variable_RespType; RespType)
            {
            }

            trigger OnPostDataItem()
            begin
                if CurrReport.Preview then
                    if not Confirm(ChangeRespQst, false) then
                        Error('');

                case RespType of
                    RespType::Release:
                        begin
                            if CashDesk."Responsibility ID (Release)" = NewRespID then
                                Error('');
                            CashDesk.Validate("Responsibility ID (Release)", NewRespID);
                            CashDesk.Modify(true);
                        end;
                    RespType::Post:
                        begin
                            if CashDesk."Responsibility ID (Post)" = NewRespID then
                                Error('');
                            CashDesk.Validate("Responsibility ID (Post)", NewRespID);
                            CashDesk.Modify(true);
                        end;
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group("Cash Desk")
                {
                    Caption = 'Cash Desk';
                    Editable = false;
                    field("CashDesk.""No."""; CashDesk."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No.';
                        ToolTip = 'Specifies the number of cash desk card.';
                    }
                    field("CashDesk.Name"; CashDesk.Name)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Name';
                        ToolTip = 'Specifies the name of cash desk card.';
                    }
                    grid(Control1000000004)
                    {
                        GridLayout = Rows;
                        ShowCaption = false;
                        group(Balance)
                        {
                            Caption = 'Balance';
                            field(Control1000000006; Balance)
                            {
                                ApplicationArea = Basic, Suite;
                                ShowCaption = false;
                                ToolTip = 'Specifies the cash desk card''s current balance denominated in the applicable foreign currency.';
                            }
                            field(CurrCode; CurrCode)
                            {
                                ApplicationArea = Basic, Suite;
                                ToolTip = 'Specifies the code of the currency of the amount on cash document line.';
                            }
                        }
                    }
                }
                group("Old Responsibility")
                {
                    Caption = 'Old Responsibility';
                    Editable = false;
                    field("CashDesk.""Responsibility ID (Release)"""; CashDesk."Responsibility ID (Release)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Responsibility ID (Release)';
                        ToolTip = 'Specifies the responsibility ID for release';
                    }
                    field("CashDesk.""Responsibility ID (Post)"""; CashDesk."Responsibility ID (Post)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Responsibility ID (Post)';
                        ToolTip = 'Specifies the responsibility ID for post';
                    }
                }
                group("New Responsibility")
                {
                    Caption = 'New Responsibility';
                    field(RespType; RespType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Responsibility';
                        OptionCaption = 'Release,Post';
                        ToolTip = 'Specifies the new responsibility for cash desk (release or post).';
                    }
                    field(NewRespID; NewRespID)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Responsibility ID';
                        ToolTip = 'Specifies the new responsibility ID for cash desk (user ID of employee).';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            CashDeskUser.FilterGroup(2);
                            CashDeskUser.SetRange("Cash Desk No.", CashDesk."No.");
                            case RespType of
                                RespType::Release:
                                    CashDeskUser.SetRange(Issue, true);
                                RespType::Post:
                                    CashDeskUser.SetRange(Post, true);
                            end;
                            CashDeskUser.FilterGroup(2);
                            if PAGE.RunModal(0, CashDeskUser) = ACTION::LookupOK then
                                NewRespID := CashDeskUser."User ID";
                        end;

                        trigger OnValidate()
                        begin
                            CashDeskUser.SetRange("Cash Desk No.", CashDesk."No.");
                            CashDeskUser.SetRange("User ID", NewRespID);
                            case RespType of
                                RespType::Release:
                                    CashDeskUser.SetRange(Issue, true);
                                RespType::Post:
                                    CashDeskUser.SetRange(Post, true);
                            end;
                            CashDeskUser.FindFirst;
                            UserSelection.ValidateUserName(NewRespID);
                        end;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
        Label_ReportName = 'Cash Desk Hand Over';
        Label_Page = 'Page';
        Label_CashDesk_No = 'Cash Desk No.';
        Label_CashDesk_Name = 'Name';
        Label_CashDesk_OldResp_Release = 'Old Responsibility ID (Release)';
        Label_CashDesk_OldResp_Post = 'Old Responsibility ID (Post)';
        Label_NewRespId_Release = 'New Responsibility ID (Release)';
        Label_NewRespId_Post = 'New Responsibility ID (Post)';
        Label_Balance = 'Balance';
        Label_Today = 'Hand Over Date';
        Label_Time = 'Hand Over Time';
        Label_Gave = 'Gave';
        Label_Take = 'Take';
    }

    var
        CashDeskUser: Record "Cash Desk User";
        CashDesk: Record "Bank Account";
        UserSelection: Codeunit "User Selection";
        RespType: Option Release,Post;
        NewRespID: Code[50];
        CurrCode: Code[10];
        Balance: Decimal;
        ChangeRespQst: Label 'Responsibility will be change.\\Do you want to continue?';

    [Scope('OnPrem')]
    procedure SetupCashDesk(CashDeskNo: Code[20])
    var
        GLSetup: Record "General Ledger Setup";
    begin
        CashDesk.Get(CashDeskNo);
        if CashDesk."Currency Code" = '' then begin
            GLSetup.Get();
            CurrCode := GLSetup."LCY Code";
        end else
            CurrCode := CashDesk."Currency Code";

        Balance := CashDesk.CalcBalance;
    end;
}

