report 11797 "Copy User Setup"
{
    Caption = 'Copy User Setup';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(FromUserId; FromUserId)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From user';
                        TableRelation = "User Setup";
                        ToolTip = 'Specifies the user name from which will be transfered the setup.';
                    }
                    field(ToUserId; ToUserId)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To User';
                        TableRelation = "User Setup";
                        ToolTip = 'Specifies source and target users';
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
    }

    trigger OnPreReport()
    begin
        UserSetup.LockTable();
        UserSetup.Get(FromUserId);
        UserSetup.CopyTo(ToUserId);
    end;

    var
        UserSetup: Record "User Setup";
        FromUserId: Code[50];
        ToUserId: Code[50];

    [Scope('OnPrem')]
    procedure SetFromUserId(NewFromUserId: Code[50])
    begin
        FromUserId := NewFromUserId;
    end;
}

