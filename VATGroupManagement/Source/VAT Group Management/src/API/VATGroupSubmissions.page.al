page 4701 "VAT Group Submissions"
{
    PageType = API;
    Caption = 'vatGroupSubmissions', Locked = true;
    APIPublisher = 'microsoft';
    APIGroup = 'vatGroup';
    APIVersion = 'v1.0';
    EntityName = 'vatGroupSubmission';
    EntitySetName = 'vatGroupSubmissions';
    ODataKeyFields = ID;
    SourceTable = "VAT Group Submission Header";
    DelayedInsert = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ChangeTrackingAllowed = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; ID)
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    Caption = 'id', Locked = true;
                    ToolTip = 'Specifies the record identifier.';
                }
                field(no; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'no', Locked = true;
                }
                field(groupMemberId; "Group Member ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'groupMemberId', Locked = true;
                }
                field(company; Company)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'company', Locked = true;
                }
                field(submittedOn; "Submitted On")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'submittedOn', Locked = true;
                }
                field(startDate; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'startDate', Locked = true;
                }
                field(endDate; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'endDate', Locked = true;
                }
                part(vatGroupSubmissionLines; "VAT Group Submission Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'lines', Locked = true;
                    EntityName = 'vatGroupSubmissionLine';
                    EntitySetName = 'vatGroupSubmissionLines';
                    SubPageLink = "VAT Group Submission ID" = field(ID);
                }

            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.Insert(true);
        exit(false);
    end;
}