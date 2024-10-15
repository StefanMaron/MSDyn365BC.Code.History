namespace Microsoft.Manufacturing.Routing;

codeunit 99000753 "Routing Line-Copy Lines"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The %1 cannot be copied to itself.';
        Text001: Label '%1 on %2 %3 must not be %4';
        Text002: Label '%1 on %2 %3 %4 must not be %5';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure CopyRouting(FromRoutingHeaderNo: Code[20]; FromVersionCode: Code[20]; var RoutingHeader: Record "Routing Header"; ToVersionCode: Code[20])
    var
        RoutingVersion: Record "Routing Version";
        RoutingLine: Record "Routing Line";
        RoutingLine2: Record "Routing Line";
        RoutingTool: Record "Routing Tool";
        FromRoutingTool: Record "Routing Tool";
        RoutingPersonnel: Record "Routing Personnel";
        FromRoutingPersonnel: Record "Routing Personnel";
        RoutingQualityMeasure: Record "Routing Quality Measure";
        FromRoutingQualityMeasure: Record "Routing Quality Measure";
        RoutingCommentLine: Record "Routing Comment Line";
        FromRoutingCommentLine: Record "Routing Comment Line";
    begin
        if (FromRoutingHeaderNo = RoutingHeader."No.") and (FromVersionCode = ToVersionCode) then
            Error(Text000, RoutingHeader.TableCaption());

        if ToVersionCode = '' then begin
            if RoutingHeader.Status = RoutingHeader.Status::Certified then
                Error(
                  Text001,
                  RoutingHeader.FieldCaption(Status),
                  RoutingHeader.TableCaption(),
                  RoutingHeader."No.",
                  RoutingHeader.Status);
        end else begin
            RoutingVersion.Get(RoutingHeader."No.", ToVersionCode);
            if RoutingVersion.Status = RoutingVersion.Status::Certified then
                Error(
                  Text002,
                  RoutingVersion.FieldCaption(Status),
                  RoutingVersion.TableCaption(),
                  RoutingVersion."Routing No.",
                  RoutingVersion."Version Code",
                  RoutingVersion.Status);
        end;

        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.SetRange("Version Code", ToVersionCode);
        RoutingLine.DeleteAll(true);

        OnAfterDeleteRouting(RoutingHeader, ToVersionCode);

        RoutingLine2.SetRange("Routing No.", FromRoutingHeaderNo);
        RoutingLine2.SetRange("Version Code", FromVersionCode);
        if RoutingLine2.Find('-') then
            repeat
                RoutingLine := RoutingLine2;
                RoutingLine."Routing No." := RoutingHeader."No.";
                RoutingLine."Version Code" := ToVersionCode;
                RoutingLine.Insert();
                OnCopyRountingOnAfterRoutingLineInsert(RoutingLine, RoutingLine2);
            until RoutingLine2.Next() = 0;

        FromRoutingTool.SetRange("Routing No.", FromRoutingHeaderNo);
        FromRoutingTool.SetRange("Version Code", FromVersionCode);
        if FromRoutingTool.Find('-') then
            repeat
                RoutingTool := FromRoutingTool;
                RoutingTool."Routing No." := RoutingHeader."No.";
                RoutingTool."Version Code" := ToVersionCode;
                RoutingTool.Insert();
            until FromRoutingTool.Next() = 0;

        FromRoutingPersonnel.SetRange("Routing No.", FromRoutingHeaderNo);
        FromRoutingPersonnel.SetRange("Version Code", FromVersionCode);
        if FromRoutingPersonnel.Find('-') then
            repeat
                RoutingPersonnel := FromRoutingPersonnel;
                RoutingPersonnel."Routing No." := RoutingHeader."No.";
                RoutingPersonnel."Version Code" := ToVersionCode;
                RoutingPersonnel.Insert();
            until FromRoutingPersonnel.Next() = 0;

        FromRoutingQualityMeasure.SetRange("Routing No.", FromRoutingHeaderNo);
        FromRoutingQualityMeasure.SetRange("Version Code", FromVersionCode);
        if FromRoutingQualityMeasure.Find('-') then
            repeat
                RoutingQualityMeasure := FromRoutingQualityMeasure;
                RoutingQualityMeasure."Routing No." := RoutingHeader."No.";
                RoutingQualityMeasure."Version Code" := ToVersionCode;
                RoutingQualityMeasure.Insert();
            until FromRoutingQualityMeasure.Next() = 0;

        FromRoutingCommentLine.SetRange("Routing No.", FromRoutingHeaderNo);
        FromRoutingCommentLine.SetRange("Version Code", FromVersionCode);
        if FromRoutingCommentLine.Find('-') then
            repeat
                RoutingCommentLine := FromRoutingCommentLine;
                RoutingCommentLine."Routing No." := RoutingHeader."No.";
                RoutingCommentLine."Version Code" := ToVersionCode;
                RoutingCommentLine.Insert();
            until FromRoutingCommentLine.Next() = 0;

        OnAfterCopyRouting(RoutingHeader, FromRoutingHeaderNo, FromVersionCode, ToVersionCode);
    end;

    procedure SelectCopyFromVersionList(var FromRoutingVersion: Record "Routing Version")
    var
        RoutingHeader: Record "Routing Header";
        OldRoutingVersion: Record "Routing Version";
    begin
        OldRoutingVersion := FromRoutingVersion;

        RoutingHeader."No." := FromRoutingVersion."Routing No.";
        if PAGE.RunModal(0, FromRoutingVersion) = ACTION::LookupOK then begin
            if OldRoutingVersion.Status = OldRoutingVersion.Status::Certified then
                Error(
                  Text002,
                  OldRoutingVersion.FieldCaption(Status),
                  OldRoutingVersion.TableCaption(),
                  OldRoutingVersion."Routing No.",
                  OldRoutingVersion."Version Code",
                  OldRoutingVersion.Status);
            CopyRouting(RoutingHeader."No.", FromRoutingVersion."Version Code", RoutingHeader, OldRoutingVersion."Version Code");
        end;
        FromRoutingVersion := OldRoutingVersion;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyRouting(var RoutingHeader: Record "Routing Header"; FromRoutingHeaderNo: Code[20]; FromVersionCode: Code[20]; ToVersionCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRouting(var RoutingHeader: Record "Routing Header"; ToVersionCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRountingOnAfterRoutingLineInsert(var RoutingLineTo: Record "Routing Line"; var RoutingLineFrom: Record "Routing Line")
    begin
    end;
}

