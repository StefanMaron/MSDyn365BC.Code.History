pageextension 4701 "VAT Report Extension" extends "VAT Report"
{
    layout
    {
        addafter("Amounts in Add. Rep. Currency")
        {
            group(VATGroupReturnControl)
            {
                Visible = IsGroupRepresentative;
                ShowCaption = false;

                field("VAT Group Return"; "VAT Group Return")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Group Included';
                    ToolTip = 'Specified whether this is a VAT group return.';
                    Editable = false;
                }
            }
            group(VATGroupStatusControl)
            {
                ShowCaption = false;
                Visible = (not "VAT Group Return") and IsGroupMember;

                field("VAT Group Status"; "VAT Group Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the VAT return on the group representative side. If this VAT return was used in a VAT group return by the group representative, the status is shown here.';
                    Editable = false;
                }
            }
        }
    }
    actions
    {
        // Add changes to page actions here
        addafter(SuggestLines)
        {
            action("Include VAT Group")
            {
                ApplicationArea = Basic, Suite;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Caption = 'Include VAT Group';
                Image = Add;
                ToolTip = 'Includes the amounts of submitted VAT returns from members in this period.';
                Visible = (not "VAT Group Return") and (Status = Status::Open) and IsGroupRepresentative;

                trigger OnAction()
                var
                    VATGroupApprovedMember: Record "VAT Group Approved Member";
                    VATGroupHelperFunctions: Codeunit "VAT Group Helper Functions";
                    VATGroupRetrievefromSubmission: Codeunit "VAT Group Retrieve From Sub.";
                begin
                    if VATGroupHelperFunctions.CountApprovedMemberSubmissionsForPeriod(Rec."Start Date", Rec."End Date") < VATGroupApprovedMember.Count() then
                        Error(NotAllMembersSubmittedErr);

                    VATGroupRetrievefromSubmission.Run(Rec);
                    Rec."VAT Group Return" := true;
                end;
            }
        }
        addafter("Include VAT Group")
        {
            action(UpdateStatus)
            {
                ApplicationArea = Basic, Suite;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Caption = 'Update Status';
                Image = ReOpen;
                ToolTip = 'Manually update the status of this VAT return to mirror the status of the VAT Group return in the group representative company. ';
                Visible = IsVATReportValid;

                trigger OnAction()
                var
                    VATGroupSubmissionStatus: Codeunit "VAT Group Submission Status";
                begin
                    VATGroupSubmissionStatus.UpdateSingleVATReportStatus(Rec."No.");
                end;
            }
        }
        modify(SuggestLines)
        {
            trigger OnAfterAction()
            var
                VATGroupHelperFunctions: Codeunit "VAT Group Helper Functions";
            begin
                VATGroupHelperFunctions.SetOriginalRepresentativeAmount(Rec);
            end;
        }
        modify(Release)
        {
            trigger OnAfterAction()
            var
                VATGroupHelperFunctions: Codeunit "VAT Group Helper Functions";
                VATGroupRetrievefromSubmission: Codeunit "VAT Group Retrieve From Sub.";
                ValuesChanged: Notification;
            begin
                if IsGroupRepresentative then begin
                    VATGroupRetrievefromSubmission.Run(Rec);
                    VATGroupHelperFunctions.MarkReleasedVATSubmissions(Rec);
                    if VATGroupRetrievefromSubmission.IsNotificationNeeded() then begin
                        ValuesChanged.Message(ValuesChangedMsg);
                        ValuesChanged.Send();
                    end;
                end;
            end;
        }
        modify(Reopen)
        {
            trigger OnAfterAction()
            var
                VATGroupHelperFunctions: Codeunit "VAT Group Helper Functions";
                VATGroupRetrievefromSubmission: Codeunit "VAT Group Retrieve From Sub.";
            begin
                VATGroupHelperFunctions.MarkReopenedVATSubmissions(Rec);
                VATGroupRetrievefromSubmission.Run(Rec);
            end;
        }
    }

    var
        VATReportSetup: Record "VAT Report Setup";
        IsGroupRepresentative: Boolean;
        IsVATReportValid: Boolean;
        IsGroupMember: Boolean;
        ValuesChangedMsg: Label 'The amounts submitted by group members have changed. Please review the new values.';
        NewerSubmissionsMsg: Label 'There are newer VAT Group submissions from members for this period. Click Reopen to incorporate the new values.';
        NotAllMembersSubmittedErr: Label 'Some VAT Group members have not submitted their VAT return for this period. Wait until all members have submitted before you continue.\n You can see the current submission on the VAT Group Submision page.';

    trigger OnAfterGetRecord()
    var
        VATGroupSubmissionStatus: Codeunit "VAT Group Submission Status";
        VATGroupHelperFunctions: Codeunit "VAT Group Helper Functions";
        NewerSubmissions: Notification;
    begin
        if not VATReportSetup.Get() then
            exit;

        IsGroupRepresentative := VATReportSetup.IsGroupRepresentative();
        IsGroupMember := VATReportSetup.IsGroupMember();
        IsVATReportValid := VATGroupSubmissionStatus.IsVATReportValid(Rec);

        if IsGroupRepresentative and (Rec.Status = Rec.Status::Released) then
            if VATGroupHelperFunctions.NewerVATSubmissionsExist(Rec) then begin
                NewerSubmissions.Id := '0ebad5d7-4655-4ff5-bc7b-bfff6b9c4b28';
                NewerSubmissions.Message(NewerSubmissionsMsg);
                NewerSubmissions.Scope(NotificationScope::LocalScope);
                NewerSubmissions.Send();
            end;
    end;
}