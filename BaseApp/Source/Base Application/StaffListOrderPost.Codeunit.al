codeunit 17368 "Staff List Order-Post"
{
    Permissions = TableData "Posted Staff List Order Header" = rim,
                  TableData "Posted Staff List Order Line" = rim;
    TableNo = "Staff List Order Header";

    trigger OnRun()
    var
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        HRSetup.Get();
        HRSetup.TestField("Use Staff List Change Orders", true);

        ClearAll;
        StaffOrderHeader := Rec;
        with StaffOrderHeader do begin
            TestField("No.");
            TestField("Document Date");

            Window.Open(
              '#1#################################\\' +
              Text000);

            Window.Update(1, StrSubstNo('%1 %2', TableCaption, "No."));

            if Status = Status::Open then
                CODEUNIT.Run(CODEUNIT::"Release Staff List Order", StaffOrderHeader);

            StaffOrderLine.LockTable();
            LockTable();

            SourceCodeSetup.Get();
            SourceCodeSetup.TestField("Vacation Order");

            // Insert posted absence header
            PostedStaffOrderHeader.LockTable();
            PostedStaffOrderHeader.Init();
            PostedStaffOrderHeader.TransferFields(StaffOrderHeader);
            PostedStaffOrderHeader.Insert();

            CopyCommentLines("No.", PostedStaffOrderHeader."No.");
            RecordLinkManagement.CopyLinks(Rec, PostedStaffOrderHeader);

            // Lines
            PostedStaffOrderLine.LockTable();

            LineCount := 0;
            StaffOrderLine.Reset();
            StaffOrderLine.SetRange("Document No.", "No.");
            if StaffOrderLine.FindSet then
                repeat
                    LineCount := LineCount + 1;
                    Window.Update(2, LineCount);

                    // insert posted lines
                    PostedStaffOrderLine.Init();
                    PostedStaffOrderLine.TransferFields(StaffOrderLine);
                    PostedStaffOrderLine.Insert();

                    case StaffOrderLine.Type of
                        StaffOrderLine.Type::Position:
                            begin
                                Position.Get(StaffOrderLine.Code);
                                case StaffOrderLine.Action of
                                    StaffOrderLine.Action::Approve:
                                        begin
                                            Position."Starting Date" := "Posting Date";
                                            Position.Approve(true);
                                        end;
                                    StaffOrderLine.Action::Reopen:
                                        Position.Reopen(true);
                                    StaffOrderLine.Action::Close:
                                        Position.Close(true);
                                end;
                            end;
                        StaffOrderLine.Type::"Org. Unit":
                            begin
                                OrgUnit.Get(StaffOrderLine.Code);
                                case StaffOrderLine.Action of
                                    StaffOrderLine.Action::Approve:
                                        OrgUnit.Approve(true);
                                    StaffOrderLine.Action::Reopen:
                                        OrgUnit.Reopen(true);
                                    StaffOrderLine.Action::Close:
                                        OrgUnit.Close(true);
                                end;
                            end;
                    end;
                until StaffOrderLine.Next() = 0;

            // Delete posted order
            StaffOrderLine.DeleteAll();
            Delete;

            Commit();
        end;
    end;

    var
        HRSetup: Record "Human Resources Setup";
        StaffOrderHeader: Record "Staff List Order Header";
        StaffOrderLine: Record "Staff List Order Line";
        PostedStaffOrderHeader: Record "Posted Staff List Order Header";
        PostedStaffOrderLine: Record "Posted Staff List Order Line";
        Text000: Label 'Posting              #2######';
        SourceCodeSetup: Record "Source Code Setup";
        HROrderComment: Record "HR Order Comment Line";
        Position: Record Position;
        OrgUnit: Record "Organizational Unit";
        Window: Dialog;
        LineCount: Integer;

    local procedure CopyCommentLines(FromNumber: Code[20]; ToNumber: Code[20])
    var
        HROrderComment2: Record "HR Order Comment Line";
    begin
        HROrderComment.SetRange("Table Name", HROrderComment."Table Name"::"SL Order");
        HROrderComment.SetRange("No.", FromNumber);
        if HROrderComment.FindSet then
            repeat
                HROrderComment2 := HROrderComment;
                HROrderComment2."Table Name" := HROrderComment2."Table Name"::"P.SL Order";
                HROrderComment2."No." := ToNumber;
                HROrderComment2.Insert();
            until HROrderComment.Next() = 0;
    end;
}

