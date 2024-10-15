codeunit 17386 "Absence Order-Post (Yes/No)"
{
    TableNo = "Absence Header";

    trigger OnRun()
    begin
        AbsenceHeader.Copy(Rec);
        Code;
        Rec := AbsenceHeader;
    end;

    var
        Text000: Label 'Do you want to post %1?';
        Text001: Label 'HR Order %1 posted successfully.';
        AbsenceHeader: Record "Absence Header";
        AbsenceHeaderPost: Codeunit "Absence Order-Post";
        Text002: Label 'Do you want to cancel %1?';
        Text003: Label '%1 canceled successfully. New %2 %3 created.';

    local procedure "Code"()
    begin
        with AbsenceHeader do begin
            if not Confirm(Text000, false, TableCaption) then
                exit;
            AbsenceHeaderPost.Run(AbsenceHeader);
            Message(Text001, TableCaption);
        end;
    end;

    [Scope('OnPrem')]
    procedure CancelOrder(var PostedAbsenceHeader: Record "Posted Absence Header")
    var
        NewDocNo: Code[20];
    begin
        if not Confirm(Text002, false, PostedAbsenceHeader.TableCaption) then
            exit;

        AbsenceHeaderPost.CancelOrder(PostedAbsenceHeader, NewDocNo);
        Message(Text003, PostedAbsenceHeader.TableCaption, AbsenceHeader.TableCaption, NewDocNo);
    end;
}

