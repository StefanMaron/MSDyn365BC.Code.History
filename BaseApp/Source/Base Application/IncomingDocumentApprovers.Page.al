page 192 "Incoming Document Approvers"
{
    Caption = 'Incoming Document Approvers';
    DataCaptionFields = "User Name";
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = User;
    SourceTableView = SORTING("User Name")
                      WHERE(State = CONST(Enabled));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("User Name"; "User Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the user''s name. If the user is required to present credentials when starting the client, this is the name that the user must present.';
                }
                field("Full Name"; "Full Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the full name of the user.';
                }
                field(IsApprover; IsApprover)
                {
                    ApplicationArea = Suite;
                    Caption = 'Approver';
                    ToolTip = 'Specifies the incoming document approver. Note that this approver is not related to approval workflows.';

                    trigger OnValidate()
                    begin
                        IncomingDocumentApprover.SetIsApprover(Rec, IsApprover);
                    end;
                }
                field("License Type"; "License Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the type of license that applies to the user. For more information, see License Types.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        IsApprover := IncomingDocumentApprover.Get("User Security ID");
    end;

    trigger OnOpenPage()
    begin
        HideExternalUsers;
    end;

    var
        IncomingDocumentApprover: Record "Incoming Document Approver";
        IsApprover: Boolean;

    local procedure HideExternalUsers()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        OriginalFilterGroup: Integer;
    begin
        if not EnvironmentInfo.IsSaaS then
            exit;

        OriginalFilterGroup := FilterGroup;
        FilterGroup := 2;
        SetFilter("License Type", '<>%1', "License Type"::"External User");
        FilterGroup := OriginalFilterGroup;
    end;
}

