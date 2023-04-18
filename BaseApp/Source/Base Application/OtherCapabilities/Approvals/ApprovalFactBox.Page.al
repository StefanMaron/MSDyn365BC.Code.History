page 9092 "Approval FactBox"
{
    Caption = 'Approval';
    PageType = CardPart;
    SourceTable = "Approval Entry";

    layout
    {
        area(content)
        {
            field(DocumentHeading; DocumentHeading)
            {
                ApplicationArea = Suite;
                Caption = 'Document';
                ToolTip = 'Specifies the document that has been approved.';
            }
            field(Status; Rec.Status)
            {
                ApplicationArea = Suite;
                ToolTip = 'Specifies the approval status for the entry:';
            }
            field("Approver ID"; Rec."Approver ID")
            {
                ApplicationArea = Suite;
                ToolTip = 'Specifies the ID of the user who must approve the document (the Approver).';

                trigger OnDrillDown()
                var
                    UserMgt: Codeunit "User Management";
                begin
                    UserMgt.DisplayUserInformation("Approver ID");
                end;
            }
            field("Date-Time Sent for Approval"; Rec."Date-Time Sent for Approval")
            {
                ApplicationArea = Suite;
                ToolTip = 'Specifies the date and the time that the document was sent for approval.';
            }
            field(Comment; Comment)
            {
                ApplicationArea = Suite;
                ToolTip = 'Specifies whether there are comments relating to the approval of the record. If you want to read the comments, choose the field to open the Approval Comment Sheet window.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        DocumentHeading := GetDocumentHeading(Rec);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        DocumentHeading := '';
        exit(FindLast());
    end;

    var
        DocumentHeading: Text[250];
        Text000: Label 'Document';

    local procedure GetDocumentHeading(ApprovalEntry: Record "Approval Entry"): Text[50]
    var
        Heading: Text[50];
    begin
        if ApprovalEntry."Document Type" = ApprovalEntry."Document Type"::" " then
            Heading := Text000
        else
            Heading := Format(ApprovalEntry."Document Type");
        Heading := Heading + ' ' + ApprovalEntry."Document No.";
        exit(Heading);
    end;

    procedure UpdateApprovalEntriesFromSourceRecord(SourceRecordID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        FilterGroup(2);
        SetRange("Record ID to Approve", SourceRecordID);
        ApprovalEntry.Copy(Rec);
        if ApprovalEntry.FindFirst() then
            SetFilter("Approver ID", '<>%1', ApprovalEntry."Sender ID");
        FilterGroup(0);
        if FindLast() then;
        CurrPage.Update(false);
    end;
}

