namespace Microsoft.Manufacturing.ProductionBOM;

codeunit 99000768 "Production BOM-Copy"
{
    TableNo = "Production BOM Header";

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

    procedure CopyBOM(BOMHeaderNo: Code[20]; FromVersionCode: Code[20]; CurrentBOMHeader: Record "Production BOM Header"; ToVersionCode: Code[20])
    var
        FromProdBOMLine: Record "Production BOM Line";
        ToProdBOMLine: Record "Production BOM Line";
        FromProdBOMCompComment: Record "Production BOM Comment Line";
        ToProdBOMCompComment: Record "Production BOM Comment Line";
        ProdBOMVersion: Record "Production BOM Version";
        SkipBOMDeletion: Boolean;
        LineNo: Integer;
    begin
        if (CurrentBOMHeader."No." = BOMHeaderNo) and
           (FromVersionCode = ToVersionCode)
        then
            Error(Text000, CurrentBOMHeader.TableCaption());

        if ToVersionCode = '' then begin
            if CurrentBOMHeader.Status = CurrentBOMHeader.Status::Certified then
                Error(
                  Text001,
                  CurrentBOMHeader.FieldCaption(Status),
                  CurrentBOMHeader.TableCaption(),
                  CurrentBOMHeader."No.",
                  CurrentBOMHeader.Status);
        end else begin
            ProdBOMVersion.Get(
              CurrentBOMHeader."No.", ToVersionCode);
            if ProdBOMVersion.Status = ProdBOMVersion.Status::Certified then
                Error(
                  Text002,
                  ProdBOMVersion.FieldCaption(Status),
                  ProdBOMVersion.TableCaption(),
                  ProdBOMVersion."Production BOM No.",
                  ProdBOMVersion."Version Code",
                  ProdBOMVersion.Status);
        end;

        LineNo := 0;
        SkipBOMDeletion := false;
        OnBeforeCopyBOM(CurrentBOMHeader, BOMHeaderNo, FromVersionCode, ToVersionCode, SkipBOMDeletion, LineNo);
        if not SkipBOMDeletion then begin
            ToProdBOMLine.SetRange("Production BOM No.", CurrentBOMHeader."No.");
            ToProdBOMLine.SetRange("Version Code", ToVersionCode);
            ToProdBOMLine.DeleteAll();

            ToProdBOMCompComment.SetRange("Production BOM No.", CurrentBOMHeader."No.");
            ToProdBOMCompComment.SetRange("Version Code", ToVersionCode);
            ToProdBOMCompComment.DeleteAll();
        end;

        FromProdBOMLine.SetRange("Production BOM No.", BOMHeaderNo);
        FromProdBOMLine.SetRange("Version Code", FromVersionCode);
        if FromProdBOMLine.Find('-') then
            repeat
                ToProdBOMLine := FromProdBOMLine;
                ToProdBOMLine."Production BOM No." := CurrentBOMHeader."No.";
                ToProdBOMLine."Version Code" := ToVersionCode;
                if SkipBOMDeletion then
                    ToProdBOMLine."Line No." := LineNo;
                OnBeforeInsertProdBOMComponent(ToProdBOMLine, FromProdBOMLine);
                ToProdBOMLine.Insert();
                OnAfterInsertProdBOMComponent(ToProdBOMLine, FromProdBOMLine, CurrentBOMHeader, SkipBOMDeletion, LineNo);
            until FromProdBOMLine.Next() = 0;

        if SkipBOMDeletion then
            exit;

        FromProdBOMCompComment.SetRange("Production BOM No.", BOMHeaderNo);
        FromProdBOMCompComment.SetRange("Version Code", FromVersionCode);
        if FromProdBOMCompComment.Find('-') then
            repeat
                ToProdBOMCompComment := FromProdBOMCompComment;
                ToProdBOMCompComment."Production BOM No." := CurrentBOMHeader."No.";
                ToProdBOMCompComment."Version Code" := ToVersionCode;
                ToProdBOMCompComment.Insert();
            until FromProdBOMCompComment.Next() = 0;

        OnAfterCopyBOM(BOMHeaderNo, CurrentBOMHeader, FromVersionCode, ToVersionCode);
    end;

    procedure CopyFromVersion(var ProdBOMVersionList2: Record "Production BOM Version")
    var
        ProdBOMHeader: Record "Production BOM Header";
        OldProdBOMVersionList: Record "Production BOM Version";
    begin
        OldProdBOMVersionList := ProdBOMVersionList2;

        ProdBOMHeader.Init();
        ProdBOMHeader."No." := ProdBOMVersionList2."Production BOM No.";
        if PAGE.RunModal(0, ProdBOMVersionList2) = ACTION::LookupOK then begin
            if OldProdBOMVersionList.Status = OldProdBOMVersionList.Status::Certified then
                Error(
                  Text002,
                  OldProdBOMVersionList.FieldCaption(Status),
                  OldProdBOMVersionList.TableCaption(),
                  OldProdBOMVersionList."Production BOM No.",
                  OldProdBOMVersionList."Version Code",
                  OldProdBOMVersionList.Status);
            CopyBOM(ProdBOMHeader."No.", ProdBOMVersionList2."Version Code", ProdBOMHeader, OldProdBOMVersionList."Version Code");
        end;

        ProdBOMVersionList2 := OldProdBOMVersionList;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyBOM(BOMHeaderNo: Code[20]; var CurrentBOMHeader: Record "Production BOM Header"; FromVersionCode: Code[20]; ToVersionCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyBOM(var ProdBOMHeader: Record "Production BOM Header"; BOMHeaderNo: Code[20]; FromVersionCode: Code[20]; ToVersionCode: Code[20]; var SkipBOMDeletion: Boolean; var LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertProdBOMComponent(var ToProductionBOMLine: Record "Production BOM Line"; var FromProductionBOMLine: Record "Production BOM Line"; var ProductionBOMHeader: Record "Production BOM Header"; var SkipBOMDeletion: Boolean; var LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertProdBOMComponent(var ToProductionBOMLine: Record "Production BOM Line"; var FromProductionBOMLine: Record "Production BOM Line")
    begin
    end;
}

