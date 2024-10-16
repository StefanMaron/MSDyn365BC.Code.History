namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Inventory.Item;
using System.Utilities;

report 99001043 "Exchange Production BOM Item"
{
    ApplicationArea = Manufacturing;
    Caption = 'Exchange Production BOM Item';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;

            trigger OnPostDataItem()
            var
                ProdBOMHeader2: Record "Production BOM Header";
                FirstVersion: Boolean;
            begin
                Window.Open(
                  Text004 +
                  Text005);

                Window.Update(1, FromBOMType);
                Window.Update(2, FromBOMNo);

                ProdBOMLine.SetCurrentKey(Type, "No.");
                ProdBOMLine.SetRange(Type, FromBOMType);
                ProdBOMLine.SetRange("No.", FromBOMNo);

                if ProdBOMLine.Find('+') then
                    repeat
                        FirstVersion := true;
                        ProdBOMHeader.Get(ProdBOMLine."Production BOM No.");
                        if ProdBOMLine."Version Code" <> '' then begin
                            ProdBOMVersionList.Get(
                              ProdBOMLine."Production BOM No.", ProdBOMLine."Version Code");
                            ProdBOMHeader.Status := ProdBOMVersionList.Status;
                            ProdBOMHeader2 := ProdBOMHeader;
                            ProdBOMHeader2."Unit of Measure Code" := ProdBOMVersionList."Unit of Measure Code";
                        end else begin
                            ProdBOMVersionList.SetRange("Production BOM No.");
                            ProdBOMVersionList."Version Code" := '';
                            ProdBOMHeader2 := ProdBOMHeader;
                        end;

                        if IsActiveBOMVersion(ProdBOMHeader, ProdBOMLine) then begin
                            Window.Update(3, ProdBOMLine."Production BOM No.");
                            if not CreateNewVersion then begin
                                if ProdBOMLine."Version Code" <> '' then begin
                                    ProdBOMVersionList.Status := ProdBOMVersionList.Status::"Under Development";
                                    ProdBOMVersionList.Modify();
                                    ProdBOMVersionList.Mark(true);
                                end else begin
                                    ProdBOMHeader.Status := ProdBOMHeader.Status::"Under Development";
                                    ProdBOMHeader.Modify();
                                    ProdBOMHeader.Mark(true);
                                end;
                            end else
                                if ProdBOMLine."Production BOM No." <> ProdBOMLine2."Production BOM No." then begin
                                    ProdBOMVersionList.SetRange("Production BOM No.", ProdBOMLine."Production BOM No.");

                                    if ProdBOMVersionList.Find('+') then
                                        ProdBOMVersionList."Version Code" := IncrementVersionNo(ProdBOMVersionList."Production BOM No.")
                                    else begin
                                        ProdBOMVersionList."Production BOM No." := ProdBOMLine."Production BOM No.";
                                        ProdBOMVersionList."Version Code" := '1';
                                    end;
                                    ProdBOMVersionList.Description := ProdBOMHeader2.Description;
                                    ProdBOMVersionList.Validate("Starting Date", StartingDate);
                                    ProdBOMVersionList."Unit of Measure Code" := ProdBOMHeader2."Unit of Measure Code";
                                    ProdBOMVersionList."Last Date Modified" := Today;
                                    ProdBOMVersionList.Status := ProdBOMVersionList.Status::New;
                                    if ProdBOMHeader2."Version Nos." <> '' then begin
                                        ProdBOMVersionList."No. Series" := ProdBOMHeader2."Version Nos.";
                                        ProdBOMVersionList."Version Code" := '';
                                        ProdBOMVersionList.Insert(true);
                                    end else
                                        ProdBOMVersionList.Insert();

                                    OnAfterProdBOMVersionListInsert(ProdBOMVersionList, ProdBOMHeader2);

                                    ProdBOMVersionList.Mark(true);
                                    ProdBOMLine3.Reset();
                                    ProdBOMLine3.SetRange("Production BOM No.", ProdBOMLine."Production BOM No.");
                                    ProdBOMLine3.SetRange("Version Code", ProdBOMLine."Version Code");
                                    if ProdBOMLine3.Find('-') then
                                        repeat
                                            if (ProdBOMLine.Type <> ProdBOMLine3.Type) or
                                               (ProdBOMLine."No." <> ProdBOMLine3."No.")
                                            then begin
                                                ProdBOMLine2 := ProdBOMLine3;
                                                ProdBOMLine2."Version Code" := ProdBOMVersionList."Version Code";
                                                ProdBOMLine2.Insert();
                                            end;
                                        until ProdBOMLine3.Next() = 0
                                    else
                                        FirstVersion := false;
                                end;

                            if (ToBOMNo <> '') and FirstVersion then
                                if CreateNewVersion then begin
                                    ProdBOMLine3.SetCurrentKey("Production BOM No.", "Version Code");
                                    ProdBOMLine3.SetRange(Type, FromBOMType);
                                    ProdBOMLine3.SetRange("No.", FromBOMNo);
                                    ProdBOMLine3.SetRange("Production BOM No.", ProdBOMLine."Production BOM No.");
                                    ProdBOMLine3.SetRange("Version Code", ProdBOMLine."Version Code");
                                    if ProdBOMLine3.Find('-') then
                                        repeat
                                            ProdBOMLine2 := ProdBOMLine3;
                                            ProdBOMLine2."Version Code" := ProdBOMVersionList."Version Code";
                                            ProdBOMLine2.Validate(Type, ToBOMType);
                                            ProdBOMLine2.Validate("No.", ToBOMNo);
                                            ProdBOMLine2.Validate("Quantity per", ProdBOMLine3."Quantity per" * QtyMultiply);
                                            if CopyRoutingLink then
                                                ProdBOMLine2.Validate("Routing Link Code", ProdBOMLine3."Routing Link Code");
                                            CopyPositionFields(ProdBOMLine2, ProdBOMLine3);
                                            ProdBOMLine2."Ending Date" := 0D;
                                            OnBeforeInsertNewProdBOMLine(ProdBOMLine2, ProdBOMLine3, QtyMultiply);
                                            ProdBOMLine2.Insert();
                                        until ProdBOMLine3.Next() = 0;
                                end else begin
                                    ProdBOMLine3.SetRange("Production BOM No.", ProdBOMLine."Production BOM No.");
                                    ProdBOMLine3.SetRange("Version Code", ProdBOMVersionList."Version Code");
                                    if not ProdBOMLine3.Find('+') then
                                        Clear(ProdBOMLine3);
                                    ProdBOMLine3."Line No." := ProdBOMLine3."Line No." + 10000;
                                    ProdBOMLine2 := ProdBOMLine;
                                    ProdBOMLine2."Version Code" := ProdBOMVersionList."Version Code";
                                    ProdBOMLine2.Validate(Type, ToBOMType);
                                    ProdBOMLine2.Validate("No.", ToBOMNo);
                                    ProdBOMLine2.Validate("Quantity per", ProdBOMLine."Quantity per" * QtyMultiply);
                                    if CopyRoutingLink then
                                        ProdBOMLine2.Validate("Routing Link Code", ProdBOMLine."Routing Link Code");
                                    if not CreateNewVersion then
                                        ProdBOMLine2."Starting Date" := StartingDate;
                                    ProdBOMLine2."Ending Date" := 0D;
                                    if DeleteExcComp then begin
                                        ProdBOMLine2."Line No." := ProdBOMLine."Line No.";
                                        CopyPositionFields(ProdBOMLine2, ProdBOMLine);
                                        ProdBOMLine.Delete(true);
                                    end else begin
                                        ProdBOMLine2."Line No." := ProdBOMLine3."Line No.";
                                        CopyPositionFields(ProdBOMLine2, ProdBOMLine3);
                                        ProdBOMLine."Ending Date" := StartingDate - 1;
                                        ProdBOMLine.Modify();
                                    end;
                                    OnBeforeInsertNewProdBOMLine(ProdBOMLine2, ProdBOMLine, QtyMultiply);
                                    ProdBOMLine2.Insert();
                                end;
                        end;
                    until ProdBOMLine.Next(-1) = 0;
            end;
        }
        dataitem(RecertifyLoop; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;

            trigger OnPreDataItem()
            begin
                OnRecertifyLoopOnBeforeOnPreDataItem(FromBOMType, FromBOMNo, ToBOMType, ToBOMNo, QtyMultiply, CreateNewVersion, StartingDate, Recertify, CopyRoutingLink, DeleteExcComp);
            end;

            trigger OnAfterGetRecord()
            var
                IsHandled: Boolean;
            begin
                if Recertify then begin
                    ProdBOMHeader.MarkedOnly(true);
                    IsHandled := false;
                    OnRecertifyLoopOnBeforeLoopProdBOMHeader(ProdBOMHeader, IsHandled);
                    if not IsHandled then
                        if ProdBOMHeader.Find('-') then
                            repeat
                                ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::Certified);
                                ProdBOMHeader.Modify();
                            until ProdBOMHeader.Next() = 0;

                    ProdBOMVersionList.SetRange("Production BOM No.");
                    ProdBOMVersionList.MarkedOnly(true);
                    IsHandled := false;
                    OnRecertifyLoopOnBeforeLoopProdBOMVersionList(ProdBOMVersionList, IsHandled);
                    if not IsHandled then
                        if ProdBOMVersionList.Find('-') then
                            repeat
                                ProdBOMVersionList.Validate(Status, ProdBOMVersionList.Status::Certified);
                                ProdBOMVersionList.Modify();
                            until ProdBOMVersionList.Next() = 0;
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
                group(Options)
                {
                    Caption = 'Options';
                    group(Exchange)
                    {
                        Caption = 'Exchange';
                        field(ExchangeType; FromBOMType)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Type';
                            ToolTip = 'Specifies what is to be exchanged here - Item or Production BOM.';

                            trigger OnValidate()
                            begin
                                FromBOMNo := '';
                            end;
                        }
                        field(ExchangeNo; FromBOMNo)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'No.';
                            ToolTip = 'Specifies the number of the item.';

                            trigger OnLookup(var Text: Text): Boolean
                            var
                                IsHandled: Boolean;
                            begin
                                case FromBOMType of
                                    FromBOMType::Item:
                                        if PAGE.RunModal(0, Item) = ACTION::LookupOK then begin
                                            Text := Item."No.";
                                            exit(true);
                                        end;
                                    FromBOMType::"Production BOM":
                                        if PAGE.RunModal(0, ProdBOMHeader) = ACTION::LookupOK then begin
                                            Text := ProdBOMHeader."No.";
                                            exit(true);
                                        end;
                                    else
                                        OnLookupExchangeNo(FromBOMType, Text, IsHandled);
                                end;
                            end;

                            trigger OnValidate()
                            begin
                                if FromBOMType = FromBOMType::" " then
                                    Error(Text006);

                                case FromBOMType of
                                    FromBOMType::Item:
                                        Item.Get(FromBOMNo);
                                    FromBOMType::"Production BOM":
                                        ProdBOMHeader.Get(FromBOMNo);
                                end;
                            end;
                        }
                    }
                    group("With")
                    {
                        Caption = 'With';
                        field(WithType; ToBOMType)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Type';
                            ToolTip = 'Specifies your new selection that will replace what you selected in the Exchange Type field - Item or Production BOM.';

                            trigger OnValidate()
                            begin
                                ToBOMNo := '';
                            end;
                        }
                        field(WithNo; ToBOMNo)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'No.';
                            ToolTip = 'Specifies the number of the item.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                case ToBOMType of
                                    ToBOMType::Item:
                                        if PAGE.RunModal(0, Item) = ACTION::LookupOK then begin
                                            Text := Item."No.";
                                            exit(true);
                                        end;
                                    ToBOMType::"Production BOM":
                                        if PAGE.RunModal(0, ProdBOMHeader) = ACTION::LookupOK then begin
                                            Text := ProdBOMHeader."No.";
                                            exit(true);
                                        end;
                                end;
                                exit(false);
                            end;

                            trigger OnValidate()
                            begin
                                if ToBOMType = ToBOMType::" " then
                                    Error(Text006);

                                case ToBOMType of
                                    ToBOMType::Item:
                                        Item.Get(ToBOMNo);
                                    ToBOMType::"Production BOM":
                                        ProdBOMHeader.Get(ToBOMNo);
                                end;
                            end;
                        }
                    }
                    field("Create New Version"; CreateNewVersion)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Create New Version';
                        Editable = CreateNewVersionEditable;
                        ToolTip = 'Specifies if you want to make the exchange in a new version.';

                        trigger OnValidate()
                        begin
                            CreateNewVersionOnAfterValidat();
                        end;
                    }
                    field(MultiplyQtyWith; QtyMultiply)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Multiply Qty. with';
                        DecimalPlaces = 0 : 5;
                        ToolTip = 'Specifies the value of a quantity change here. If the quantity is to remain the same, enter 1 here. If you enter 2, the new quantities doubled in comparison with original quantity.';
                    }
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which these changes are to become valid.';
                    }
                    field(Recertify; Recertify)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Recertify';
                        ToolTip = 'Specifies if you want the production BOM to be certified after the change.';
                    }
                    field(CopyRoutingLink; CopyRoutingLink)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Copy Routing Link';
                        ToolTip = 'Specifies whether or not you want the routing link copied.';
                    }
                    field("Delete Exchanged Component"; DeleteExcComp)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Delete Exchanged Component';
                        Editable = DeleteExchangedComponentEditab;
                        ToolTip = 'Specifies whether you want the exchanged component deleted.';

                        trigger OnValidate()
                        begin
                            DeleteExcCompOnAfterValidate();
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            DeleteExchangedComponentEditab := true;
            CreateNewVersionEditable := true;
            CreateNewVersion := true;
            QtyMultiply := 1;
            StartingDate := WorkDate();

            OnAfterOnInitReport(CreateNewVersion, StartingDate, DeleteExcComp);
        end;

        trigger OnOpenPage()
        begin
            CreateNewVersionEditable := not DeleteExcComp;
            DeleteExchangedComponentEditab := not CreateNewVersion;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        Recertify := true;
        CopyRoutingLink := true;
    end;

    trigger OnPreReport()
    begin
        CheckParameters();
    end;

    var
        Item: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersionList: Record "Production BOM Version";
        ProdBOMLine: Record "Production BOM Line";
        ProdBOMLine2: Record "Production BOM Line";
        ProdBOMLine3: Record "Production BOM Line";
        Window: Dialog;
        FromBOMType: Enum "Production BOM Line Type";
        FromBOMNo: Code[20];
        ToBOMType: Enum "Production BOM Line Type";
        ToBOMNo: Code[20];
        QtyMultiply: Decimal;
        CreateNewVersion: Boolean;
        StartingDate: Date;
        Recertify: Boolean;
        CopyRoutingLink: Boolean;
        DeleteExcComp: Boolean;
        CreateNewVersionEditable: Boolean;
        DeleteExchangedComponentEditab: Boolean;

#pragma warning disable AA0074
        Text000: Label 'You must enter a Starting Date.';
        Text001: Label 'You must enter the Type to exchange.';
        Text002: Label 'You must enter the No. to exchange.';
#pragma warning restore AA0074
        ItemBOMExchangeErr: Label 'You cannot exchange %1 %2 with %3 %4.', Comment = '%1 and %3 are strings (''Item'' or ''Production BOM''), %2 and %4 are either an Item No. or a Production BOM Header No. (Code[20])';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'Exchanging #1########## #2############\';
        Text005: Label 'Production BOM No.      #3############';
#pragma warning restore AA0470
        Text006: Label 'Type must be entered.';
#pragma warning restore AA0074

    local procedure CheckParameters()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckParameters(StartingDate, FromBOMType, FromBOMNo, ToBOMType, ToBOMNo, IsHandled);
        if IsHandled then
            exit;

        if StartingDate = 0D then
            Error(Text000);

        if FromBOMType = FromBOMType::" " then
            Error(Text001);

        if FromBOMNo = '' then
            Error(Text002);

        if (FromBOMType = ToBOMType) and (FromBOMNo = ToBOMNo) then
            Error(ItemBOMExchangeErr, FromBOMType, FromBOMNo, ToBOMType, ToBOMNo);
    end;

    local procedure CreateNewVersionOnAfterValidat()
    begin
        CreateNewVersionEditable := not DeleteExcComp;
        DeleteExchangedComponentEditab := not CreateNewVersion;
    end;

    local procedure DeleteExcCompOnAfterValidate()
    begin
        CreateNewVersionEditable := not DeleteExcComp;
        DeleteExchangedComponentEditab := not CreateNewVersion;
    end;

    local procedure IsActiveBOMVersion(ProdBOMHeader: Record "Production BOM Header"; ProdBOMLine: Record "Production BOM Line"): Boolean
    var
        VersionManagement: Codeunit VersionManagement;
    begin
        if ProdBOMHeader.Status = ProdBOMHeader.Status::Closed then
            exit(false);

        exit(ProdBOMLine."Version Code" = VersionManagement.GetBOMVersion(ProdBOMLine."Production BOM No.", StartingDate, true));
    end;

    local procedure IncrementVersionNo(ProductionBOMNo: Code[20]) Result: Code[20]
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        ProductionBOMVersion.SetRange("Production BOM No.", ProductionBOMNo);
        if ProductionBOMVersion.FindLast() then begin
            Result := IncStr(ProductionBOMVersion."Version Code");
            ProductionBOMVersion.SetRange("Version Code", Result);
            while not ProductionBOMVersion.IsEmpty() do begin
                Result := IncStr(Result);
                if Result = '' then
                    exit(Result);
                ProductionBOMVersion.SetRange("Version Code", Result);
            end;
        end;
    end;

    local procedure CopyPositionFields(var ProdBOMLineCopyTo: Record "Production BOM Line"; ProdBOMLineCopyFrom: Record "Production BOM Line")
    begin
        if (ProdBOMLineCopyTo.Type <> ProdBOMLineCopyTo.Type::Item) or (ProdBOMLineCopyFrom.Type <> ProdBOMLineCopyFrom.Type::Item) then
            exit;
        ProdBOMLineCopyTo.Validate(Position, ProdBOMLineCopyFrom.Position);
        ProdBOMLineCopyTo.Validate("Position 2", ProdBOMLineCopyFrom."Position 2");
        ProdBOMLineCopyTo.Validate("Position 3", ProdBOMLineCopyFrom."Position 3");

        OnAfterCopyPositionFields(ProdBOMLineCopyTo, ProdBOMLineCopyFrom);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPositionFields(var ProdBOMLineCopyTo: Record "Production BOM Line"; ProdBOMLineCopyFrom: Record "Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdBOMVersionListInsert(var ProductionBOMVersion: Record "Production BOM Version"; ProductionBOMHeader: Record "Production BOM Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewProdBOMLine(var ProductionBOMLine: Record "Production BOM Line"; var FromProductionBOMLine: Record "Production BOM Line"; QtyMultiply: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupExchangeNo(LineType: Enum "Production BOM Line Type"; LookupText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecertifyLoopOnBeforeOnPreDataItem(FromBOMType: Enum "Production BOM Line Type"; FromBOMNo: Code[20]; ToBOMType: Enum "Production BOM Line Type"; ToBOMNo: Code[20]; QtyMultiply: Decimal; CreateNewVersion: Boolean; StartingDate: Date; Recertify: Boolean; CopyRoutingLink: Boolean; DeleteExcComp: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckParameters(StartingDate: Date; FromBOMType: Enum "Production BOM Line Type"; FromBOMNo: Code[20]; ToBOMType: Enum "Production BOM Line Type"; ToBOMNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInitReport(var CreateNewVersion: Boolean; var StartingDate: Date; var DeleteExcComp: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecertifyLoopOnBeforeLoopProdBOMHeader(var ProductionBOMHeader: Record "Production BOM Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecertifyLoopOnBeforeLoopProdBOMVersionList(var ProductionBOMVersion: Record "Production BOM Version"; var IsHandled: Boolean)
    begin
    end;
}

