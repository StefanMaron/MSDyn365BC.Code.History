codeunit 7030 "Campaign Target Group Mgt"
{

    trigger OnRun()
    begin
    end;

    var
        ContBusRel: Record "Contact Business Relation";
        SegLine: Record "Segment Line";
        CampaignTargetGr: Record "Campaign Target Group";
        Text000: Label '%1 %2 is now activated.';
        Text001: Label '%1 %2 is now deactivated.';
        Text002: Label 'To activate the sales prices and/or line discounts, you must apply the relevant %1(s) to the %2 and place a check mark in the %3 field on the %1.';
        InteractLogEntry: Record "Interaction Log Entry";
        Text004: Label 'There are no Sales Prices or Sales Line Discounts currently linked to this %1. Do you still want to activate?';
        Text006: Label 'Activating prices for the Contacts...\\';
        Text007: Label 'Segment Lines  @1@@@@@@@@@@';
        Text008: Label 'Logged Segment Lines  @1@@@@@@@@@@';

    procedure ActivateCampaign(var Campaign: Record Campaign)
    var
        SalesPrice: Record "Sales Price";
        SalesLineDisc: Record "Sales Line Discount";
        ConfirmManagement: Codeunit "Confirm Management";
        Window: Dialog;
        Found: Boolean;
        Continue: Boolean;
        NoOfRecords: Integer;
        i: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeActivateCampaign(Campaign, IsHandled);
        if IsHandled then
            exit;

        SalesPrice.SetCurrentKey("Sales Type", "Sales Code");
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::Campaign);
        SalesPrice.SetRange("Sales Code", Campaign."No.");
        SalesLineDisc.SetCurrentKey("Sales Type", "Sales Code");
        SalesLineDisc.SetRange("Sales Type", SalesLineDisc."Sales Type"::Campaign);
        SalesLineDisc.SetRange("Sales Code", Campaign."No.");
        if not (SalesPrice.FindFirst or SalesLineDisc.FindFirst) then begin
            Continue :=
              ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text004, Campaign.TableCaption), true);
            if Continue = false then
                exit;
        end;
        CampaignTargetGr.LockTable();
        Found := false;

        with SegLine do begin
            SetCurrentKey("Campaign No.");
            SetRange("Campaign No.", Campaign."No.");
            SetRange("Campaign Target", true);

            if Find('-') then begin
                Found := true;
                i := 0;
                Window.Open(
                  Text006 +
                  Text007);
                NoOfRecords := Count;
                repeat
                    i := i + 1;
                    AddSegLinetoTargetGr(SegLine);
                    Window.Update(1, Round(i / NoOfRecords * 10000, 1));
                until Next = 0;
                Window.Close;
            end;
        end;

        with InteractLogEntry do begin
            SetCurrentKey("Campaign No.", "Campaign Target");
            SetRange("Campaign No.", Campaign."No.");
            SetRange("Campaign Target", true);
            SetRange(Postponed, false);
            if Find('-') then begin
                Found := true;
                i := 0;
                Window.Open(
                  Text006 +
                  Text008);
                NoOfRecords := Count;
                repeat
                    i := i + 1;
                    AddInteractionLogEntry(InteractLogEntry);
                    Window.Update(1, Round(i / NoOfRecords * 10000, 1));
                until Next = 0;
                Window.Close;
            end;
        end;
        if Found then begin
            Commit();
            Message(Text000, Campaign.TableCaption, Campaign."No.")
        end else
            Error(Text002, SegLine.TableCaption, Campaign.TableCaption, SegLine.FieldCaption("Campaign Target"));
    end;

    procedure DeactivateCampaign(var Campaign: Record Campaign; ShowMessage: Boolean)
    begin
        CampaignTargetGr.LockTable();

        CampaignTargetGr.SetCurrentKey("Campaign No.");
        CampaignTargetGr.SetRange("Campaign No.", Campaign."No.");
        if not CampaignTargetGr.IsEmpty then
            CampaignTargetGr.DeleteAll();
        if ShowMessage then
            Message(Text001, Campaign.TableCaption, Campaign."No.");
    end;

    procedure AddSegLinetoTargetGr(SegLine: Record "Segment Line")
    begin
        with SegLine do
            if ("Campaign No." <> '') and "Campaign Target" then begin
                ContBusRel.SetCurrentKey("Link to Table", "Contact No.");
                ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                ContBusRel.SetRange("Contact No.", "Contact Company No.");
                if ContBusRel.FindFirst then
                    InsertTargetGroup(CampaignTargetGr.Type::Customer, ContBusRel."No.", "Campaign No.")
                else
                    InsertTargetGroup(
                      CampaignTargetGr.Type::Contact, "Contact Company No.", "Campaign No.");
                OnAfterAddSegLineToTargetGroup(CampaignTargetGr, SegLine);
            end;
    end;

    procedure DeleteSegfromTargetGr(SegLine: Record "Segment Line")
    var
        SegLine2: Record "Segment Line";
    begin
        with SegLine do
            if "Campaign No." <> '' then begin
                SegLine2.SetCurrentKey("Campaign No.", "Contact Company No.", "Campaign Target");
                SegLine2.SetRange("Campaign No.", "Campaign No.");
                SegLine2.SetRange("Contact Company No.", "Contact Company No.");
                SegLine2.SetRange("Campaign Target", true);

                InteractLogEntry.SetCurrentKey("Campaign No.", "Contact Company No.", "Campaign Target");
                InteractLogEntry.SetRange("Campaign No.", "Campaign No.");
                InteractLogEntry.SetRange("Contact Company No.", "Contact Company No.");
                InteractLogEntry.SetRange("Campaign Target", true);
                InteractLogEntry.SetRange(Postponed, false);

                if SegLine2.Count + InteractLogEntry.Count = 1 then begin
                    ContBusRel.SetCurrentKey("Link to Table", "Contact No.");
                    ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                    ContBusRel.SetRange("Contact No.", "Contact Company No.");

                    if ContBusRel.FindFirst then begin
                        if CampaignTargetGr.Get(
                             CampaignTargetGr.Type::Customer, ContBusRel."No.", "Campaign No.")
                        then
                            CampaignTargetGr.Delete();
                    end else
                        if CampaignTargetGr.Get(
                             CampaignTargetGr.Type::Contact, "Contact No.", "Campaign No.")
                        then
                            CampaignTargetGr.Delete();
                end;
            end;
    end;

    procedure AddInteractionLogEntry(InteractionLogEntry: Record "Interaction Log Entry")
    begin
        with InteractionLogEntry do
            if ("Campaign No." <> '') and "Campaign Target" then begin
                ContBusRel.SetCurrentKey("Link to Table", "Contact No.");
                ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                ContBusRel.SetRange("Contact No.", "Contact Company No.");
                if ContBusRel.FindFirst then
                    InsertTargetGroup(CampaignTargetGr.Type::Customer, ContBusRel."No.", "Campaign No.")
                else
                    InsertTargetGroup(
                      CampaignTargetGr.Type::Contact, "Contact Company No.", "Campaign No.");
            end;
    end;

    procedure DeleteContfromTargetGr(InteractLogEntry: Record "Interaction Log Entry")
    var
        InteractLogEntry2: Record "Interaction Log Entry";
    begin
        with InteractLogEntry do
            if "Campaign No." <> '' then begin
                InteractLogEntry2.SetCurrentKey("Campaign No.", "Contact Company No.", "Campaign Target");
                InteractLogEntry2.SetRange("Campaign No.", "Campaign No.");
                InteractLogEntry2.SetRange("Contact Company No.", "Contact Company No.");
                InteractLogEntry2.SetRange("Campaign Target", true);
                InteractLogEntry2.SetRange(Postponed, false);

                SegLine.SetCurrentKey("Campaign No.", "Contact Company No.", "Campaign Target");
                SegLine.SetRange("Campaign No.", "Campaign No.");
                SegLine.SetRange("Contact Company No.", "Contact Company No.");
                SegLine.SetRange("Campaign Target", true);

                if InteractLogEntry2.Count + Count = 1 then begin
                    ContBusRel.SetCurrentKey("Link to Table", "Contact No.");
                    ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                    ContBusRel.SetRange("Contact No.", "Contact Company No.");

                    if ContBusRel.FindFirst then begin
                        if CampaignTargetGr.Get(
                             CampaignTargetGr.Type::Customer, ContBusRel."No.", "Campaign No.")
                        then
                            CampaignTargetGr.Delete();
                    end else
                        if CampaignTargetGr.Get(
                             CampaignTargetGr.Type::Contact, "Contact No.", "Campaign No.")
                        then
                            CampaignTargetGr.Delete();
                end;
            end;
    end;

    procedure ConverttoCustomer(Contact: Record Contact; Customer: Record Customer)
    var
        CampaignTargetGr2: Record "Campaign Target Group";
    begin
        with Contact do begin
            CampaignTargetGr2.SetCurrentKey("No.");
            CampaignTargetGr2.SetRange("No.", "No.");
            if CampaignTargetGr2.Find('-') then
                repeat
                    InsertTargetGroup(
                      CampaignTargetGr2.Type::Customer, Customer."No.", CampaignTargetGr2."Campaign No.");
                    CampaignTargetGr2.Delete();
                until CampaignTargetGr2.Next = 0;
        end;
    end;

    procedure ConverttoContact(Cust: Record Customer; CompanyContNo: Code[20])
    var
        CampaignTargetGr2: Record "Campaign Target Group";
    begin
        with Cust do begin
            CampaignTargetGr2.SetRange("No.", "No.");
            if CampaignTargetGr2.Find('-') then
                repeat
                    InsertTargetGroup(
                      CampaignTargetGr2.Type::Contact, CompanyContNo, CampaignTargetGr2."Campaign No.");
                    CampaignTargetGr2.Delete();
                until CampaignTargetGr2.Next = 0;
        end;
    end;

    local procedure InsertTargetGroup(Type: Option; No: Code[20]; CampaignNo: Code[20])
    begin
        CampaignTargetGr.Type := Type;
        CampaignTargetGr."No." := No;
        CampaignTargetGr."Campaign No." := CampaignNo;
        CampaignTargetGr.Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddSegLineToTargetGroup(var CampaignTargetGr: Record "Campaign Target Group"; var SegLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeActivateCampaign(var Campaign: Record Campaign; var IsHandled: Boolean)
    begin
    end;
}

