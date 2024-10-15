// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment;

using System.Environment.Configuration;
using System.Azure.Identity;
using Microsoft.Manufacturing.Document;
using Microsoft.Service.Archive;
using Microsoft.Service.Document;
using Microsoft.Service.Setup;
using Microsoft.Service.Item;
using Microsoft.Service.Pricing;
using Microsoft.Service.Comment;
using Microsoft.Service.Ledger;
using Microsoft.Service.Contract;
using Microsoft.RoleCenters;
using Microsoft.Service.Posting;
using Microsoft.Service.Email;
using Microsoft.Service.History;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Comment;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Family;
using Microsoft.Inventory.Tracking;

codeunit 257 "Experience Tier"
{
    Access = Internal;
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    var
        BasicCannotAccessPremiumCompanyErr: Label 'You cannot access company %1 as the experience tier of the company is premium and you are using a basic license.', Comment = '%1 - Company name';
        CannotInsertErr: Label 'You cannot insert into table %1. Premium features are blocked since you are accessing a non-premium company.', Comment = '%1 - Table caption';
        DontShowAgainTxt: Label 'Don''t show again.';
        EssentialsCannotAccessPremiumCompanyErr: Label 'You cannot access company %1 as the experience tier of the company is premium and you are using an essentials license.', Comment = '%1 - Company name';
        PremiumAccessEssentialCompanyTelemetryMsg: Label 'Premium user accessing non-premium company. Disabling premium functionality.', Locked = true;
        PremiumAccessEssentialCompanyMsg: Label 'Premium features are blocked since you are accessing a non-premium company.';
        PremiumAccessEssentialWarningNameTxt: Label 'Experience tier mismatch';
        PremiumAccessEssentialWarningDescTxt: Label 'Warns user when accessing a non-premium company using a premium license.';
        ExperienceTierCategoryTok: Label 'Experience Tier', Locked = true;

    procedure CheckExperienceTier()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        AzureADPlan: Codeunit "Azure AD Plan";
        ExperienceTier: Codeunit "Experience Tier";
        UserPlanExperience: Enum "User Plan Experience";
    begin
        UserPlanExperience := AzureADPlan.GetUserPlanExperience();

        if ApplicationAreaMgmtFacade.IsPremiumExperienceEnabled() then
            case UserPlanExperience of
                UserPlanExperience::Basic:
                    Error(BasicCannotAccessPremiumCompanyErr, CompanyName());
                UserPlanExperience::Essentials:
                    Error(EssentialsCannotAccessPremiumCompanyErr, CompanyName());
                UserPlanExperience::Premium:
                    exit;
            end;

        if UserPlanExperience = UserPlanExperience::Premium then begin
            Session.LogMessage('0000MHE', PremiumAccessEssentialCompanyTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExperienceTierCategoryTok);
            BindSubscription(ExperienceTier);
        end;
    end;

    procedure ShowExperienceMismatchNotification()
    var
        MyNotifications: Record "My Notifications";
        ExperienceNotification: Notification;
    begin
        if not MyNotifications.IsEnabled(GetExperienceMismatchNotificationId()) then
            exit;

        ExperienceNotification.Id := GetExperienceMismatchNotificationId();
        ExperienceNotification.Recall();
        ExperienceNotification.Message := PremiumAccessEssentialCompanyMsg;
        ExperienceNotification.AddAction(DontShowAgainTxt, Codeunit::"Experience Tier", 'DisableExperienceMismatchNotification');
        ExperienceNotification.Send();
    end;

    procedure DisableExperienceMismatchNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetExperienceMismatchNotificationId()) then
            MyNotifications.InsertDefault(GetExperienceMismatchNotificationId(), PremiumAccessEssentialWarningNameTxt, PremiumAccessEssentialWarningDescTxt, false);
    end;

    local procedure GetExperienceMismatchNotificationId(): Guid
    begin
        exit('3c50c1eb-cb7b-403f-bf5f-af0405547750');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Role Center Notification Mgt.", 'OnBeforeShowNotifications', '', false, false)]
    local procedure SendExperienceMismatchNotification()
    begin
        ShowExperienceMismatchNotification();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Order", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProductionOrder(RunTrigger: Boolean; var Rec: Record "Production Order")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderLine(RunTrigger: Boolean; var Rec: Record "Prod. Order Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Component", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderComponent(RunTrigger: Boolean; var Rec: Record "Prod. Order Component")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderRoutingLine(RunTrigger: Boolean; var Rec: Record "Prod. Order Routing Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Capacity Need", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderCapacityNeed(RunTrigger: Boolean; var Rec: Record "Prod. Order Capacity Need")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Tool", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderRoutingTool(RunTrigger: Boolean; var Rec: Record "Prod. Order Routing Tool")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Routing Personnel", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderRoutingPersonnel(RunTrigger: Boolean; var Rec: Record "Prod. Order Routing Personnel")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Rtng Qlty Meas.", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderRtngQltyMeas(RunTrigger: Boolean; var Rec: Record "Prod. Order Rtng Qlty Meas.")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Comment Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderCommentLine(RunTrigger: Boolean; var Rec: Record "Prod. Order Comment Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Rtng Comment Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderRtngCommentLine(RunTrigger: Boolean; var Rec: Record "Prod. Order Rtng Comment Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Comp. Cmt Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProdOrderCompCmtLine(RunTrigger: Boolean; var Rec: Record "Prod. Order Comp. Cmt Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceHeader(RunTrigger: Boolean; var Rec: Record "Service Header")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceItemLine(RunTrigger: Boolean; var Rec: Record "Service Item Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceLine(RunTrigger: Boolean; var Rec: Record "Service Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Order Type", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceOrderType(RunTrigger: Boolean; var Rec: Record "Service Order Type")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item Group", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceItemGroup(RunTrigger: Boolean; var Rec: Record "Service Item Group")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cost", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceCost(RunTrigger: Boolean; var Rec: Record "Service Cost")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Comment Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceCommentLine(RunTrigger: Boolean; var Rec: Record "Service Comment Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Ledger Entry", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceLedgerEntry(RunTrigger: Boolean; var Rec: Record "Service Ledger Entry")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Hour", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceHour(RunTrigger: Boolean; var Rec: Record "Service Hour")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Document Log", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceDocumentLog(RunTrigger: Boolean; var Rec: Record "Service Document Log")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Status Priority Setup", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceStatusPrioritySetup(RunTrigger: Boolean; var Rec: Record "Service Status Priority Setup")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Shelf", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceShelf(RunTrigger: Boolean; var Rec: Record "Service Shelf")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Order Posting Buffer", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceOrderPostingBuffer(RunTrigger: Boolean; var Rec: Record "Service Order Posting Buffer")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Register", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceRegister(RunTrigger: Boolean; var Rec: Record "Service Register")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Email Queue", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceEmailQueue(RunTrigger: Boolean; var Rec: Record "Service Email Queue")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Document Register", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceDocumentRegister(RunTrigger: Boolean; var Rec: Record "Service Document Register")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceItem(RunTrigger: Boolean; var Rec: Record "Service Item")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item Component", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceItemComponent(RunTrigger: Boolean; var Rec: Record "Service Item Component")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item Log", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceItemLog(RunTrigger: Boolean; var Rec: Record "Service Item Log")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Order Allocation", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceOrderAllocation(RunTrigger: Boolean; var Rec: Record "Service Order Allocation")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Zone", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceZone(RunTrigger: Boolean; var Rec: Record "Service Zone")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceContractLine(RunTrigger: Boolean; var Rec: Record "Service Contract Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceContractHeader(RunTrigger: Boolean; var Rec: Record "Service Contract Header")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Template", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceContractTemplate(RunTrigger: Boolean; var Rec: Record "Service Contract Template")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Filed Service Contract Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertFiledServiceContractHeader(RunTrigger: Boolean; var Rec: Record "Filed Service Contract Header")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Contract/Service Discount", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertContractServiceDiscount(RunTrigger: Boolean; var Rec: Record "Contract/Service Discount")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Account Group", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceContractAccountGroup(RunTrigger: Boolean; var Rec: Record "Service Contract Account Group")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Shipment Item Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceShipmentItemLine(RunTrigger: Boolean; var Rec: Record "Service Shipment Item Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Shipment Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceShipmentHeader(RunTrigger: Boolean; var Rec: Record "Service Shipment Header")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Shipment Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceShipmentLine(RunTrigger: Boolean; var Rec: Record "Service Shipment Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceInvoiceHeader(RunTrigger: Boolean; var Rec: Record "Service Invoice Header")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceInvoiceLine(RunTrigger: Boolean; var Rec: Record "Service Invoice Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceCrMemoHeader(RunTrigger: Boolean; var Rec: Record "Service Cr.Memo Header")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceCrMemoLine(RunTrigger: Boolean; var Rec: Record "Service Cr.Memo Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Price Group", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServicePriceGroup(RunTrigger: Boolean; var Rec: Record "Service Price Group")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Serv. Price Group Setup", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServPriceGroupSetup(RunTrigger: Boolean; var Rec: Record "Serv. Price Group Setup")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Price Adjustment Group", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServicePriceAdjustmentGroup(RunTrigger: Boolean; var Rec: Record "Service Price Adjustment Group")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Serv. Price Adjustment Detail", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServPriceAdjustmentDetail(RunTrigger: Boolean; var Rec: Record "Serv. Price Adjustment Detail")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line Price Adjmt.", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceLinePriceAdjmt(RunTrigger: Boolean; var Rec: Record "Service Line Price Adjmt.")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header Archive", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceHeaderArchive(RunTrigger: Boolean; var Rec: Record "Service Header Archive")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line Archive", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceLineArchive(RunTrigger: Boolean; var Rec: Record "Service Line Archive")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Comment Line Archive", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceCommentLineArchive(RunTrigger: Boolean; var Rec: Record "Service Comment Line Archive")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item Line Archive", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceItemLineArchive(RunTrigger: Boolean; var Rec: Record "Service Item Line Archive")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Order Allocat. Archive", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertServiceOrderAllocArchive(RunTrigger: Boolean; var Rec: Record "Service Order Allocat. Archive")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Work Shift", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertWorkShift(RunTrigger: Boolean; var Rec: Record "Work Shift")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Shop Calendar", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertShopCalendar(RunTrigger: Boolean; var Rec: Record "Shop Calendar")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Shop Calendar Working Days", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertShopCalendarWorkingDays(RunTrigger: Boolean; var Rec: Record "Shop Calendar Working Days")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Shop Calendar Holiday", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertShopCalendarHoliday(RunTrigger: Boolean; var Rec: Record "Shop Calendar Holiday")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Work Center Group", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertWorkCenterGroup(RunTrigger: Boolean; var Rec: Record "Work Center Group")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Calendar Entry", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertCalendarEntry(RunTrigger: Boolean; var Rec: Record "Calendar Entry")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Machine Center", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertMachineCenter(RunTrigger: Boolean; var Rec: Record "Machine Center")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Calendar Absence Entry", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertCalendarAbsenceEntry(RunTrigger: Boolean; var Rec: Record "Calendar Absence Entry")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Stop", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertStop(RunTrigger: Boolean; var Rec: Record "Stop")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Scrap", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertScrap(RunTrigger: Boolean; var Rec: Record "Scrap")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Routing Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertRoutingHeader(RunTrigger: Boolean; var Rec: Record "Routing Header")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Routing Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertRoutingLine(RunTrigger: Boolean; var Rec: Record "Routing Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Manufacturing Comment Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertManufacturingCommentLine(RunTrigger: Boolean; var Rec: Record "Manufacturing Comment Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production BOM Header", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProductionBOMHeader(RunTrigger: Boolean; var Rec: Record "Production BOM Header")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production BOM Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProductionBOMLine(RunTrigger: Boolean; var Rec: Record "Production BOM Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Family", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertFamily(RunTrigger: Boolean; var Rec: Record "Family")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Family Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertFamilyLine(RunTrigger: Boolean; var Rec: Record "Family Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Routing Comment Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertRoutingCommentLine(RunTrigger: Boolean; var Rec: Record "Routing Comment Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production BOM Comment Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProductionBOMCommentLine(RunTrigger: Boolean; var Rec: Record "Production BOM Comment Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Routing Link", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertRoutingLink(RunTrigger: Boolean; var Rec: Record "Routing Link")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Standard Task", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockINsertStandardTask(RunTrigger: Boolean; var Rec: Record "Standard Task")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production BOM Version", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProductionBOMVersion(RunTrigger: Boolean; var Rec: Record "Production BOM Version")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Capacity Unit of Measure", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertCapacityUnitofMeasure(RunTrigger: Boolean; var Rec: Record "Capacity Unit of Measure")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Standard Task Tool", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockINsertStandardTaskTool(RunTrigger: Boolean; var Rec: Record "Standard Task Tool")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Standard Task Personnel", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockINsertStandardTaskPersonnel(RunTrigger: Boolean; var Rec: Record "Standard Task Personnel")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Standard Task Description", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockINsertStandardTaskDescription(RunTrigger: Boolean; var Rec: Record "Standard Task Description")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Standard Task Quality Measure", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockINsertStandardTaskQualityMeasure(RunTrigger: Boolean; var Rec: Record "Standard Task Quality Measure")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Quality Measure", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertQualityMeasure(RunTrigger: Boolean; var Rec: Record "Quality Measure")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Routing Version", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertRoutingVersion(RunTrigger: Boolean; var Rec: Record "Routing Version")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Matrix BOM Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProductionMatrixBOMLine(RunTrigger: Boolean; var Rec: Record "Production Matrix BOM Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Matrix  BOM Entry", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertProductionMatrixBOMEntry(RunTrigger: Boolean; var Rec: Record "Production Matrix  BOM Entry")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Where-Used Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertWhereUsedLine(RunTrigger: Boolean; var Rec: Record "Where-Used Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Routing Tool", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertRoutingTool(RunTrigger: Boolean; var Rec: Record "Routing Tool")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Routing Personnel", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertRoutingPersonnel(RunTrigger: Boolean; var Rec: Record "Routing Personnel")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Routing Quality Measure", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertRoutingQualityMeasure(RunTrigger: Boolean; var Rec: Record "Routing Quality Measure")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Planning Routing Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertPlanningRoutingLine(RunTrigger: Boolean; var Rec: Record "Planning Routing Line")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Registered Absence", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertRegisteredAbsence(RunTrigger: Boolean; var Rec: Record "Registered Absence")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertInventoryProfile(RunTrigger: Boolean; var Rec: Record "Inventory Profile")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Capacity Constrained Resource", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BlockInsertCapacityConstrainedResource(RunTrigger: Boolean; var Rec: Record "Capacity Constrained Resource")
    begin
        Error(CannotInsertErr, Rec.TableCaption());
    end;
}

