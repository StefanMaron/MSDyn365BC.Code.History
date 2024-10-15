// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Exposes functionality to set up and retrieve styles for cues.
/// </summary>
codeunit 9701 "Cues And KPIs"
{
    SingleInstance = true;
    Access = Public;

    var
        CuesAndKPIsImpl: Codeunit "Cues And KPIs Impl.";

    /// <summary>
    /// Opens the cue setup user page with an implicit filter on table id.
    /// The page shows previously added entries in the Cue Setup Administration page that have the UserId being either the current user or blank.
    /// The page also displays all other fields the that the passed table might have of type decimal or integer.
    /// Closing this page will transfer any changed or added setup entries to the cue setup table.
    /// </summary>
    /// <param name="TableId">The ID of the table for which the page will be customized.</param>
    procedure OpenCustomizePageForCurrentUser(TableId: Integer)
    begin
        CuesAndKPIsImpl.OpenCustomizePageForCurrentUser(TableId);
    end;

    /// <summary>
    /// Changes the user of a cue setup entry.
    /// A Recref pointing to the newly modified record is returned by var.
    /// </summary>
    /// <param name="RecRef">The recordref that poins to the record that will be modified.</param>
    /// <param name="Company">The company in which the table will be modified.</param>
    /// <param name="UserName">The new UserName to which the setup entry will belong to.</param>
    [Scope('OnPrem')]
    procedure ChangeUserForSetupEntry(var RecRef: RecordRef; Company: Text[30]; UserName: Text[50])
    begin
        CuesAndKPIsImpl.ChangeUserForSetupEntry(RecRef, Company, UserName);
    end;

    /// <summary>
    /// Retrieves a Cues And KPIs Style enum based on the cue setup of the provided TableId, FieldID and Amount.
    /// The computed cue style is returned by var.
    /// </summary>
    /// <param name="TableID">The ID of the table containing the field for which the style is wanted.</param>
    /// <param name="FieldID">The ID of the field for which the style is wanted.</param>
    /// <param name="Amount">The amount for which the style will be calculated based on the threshold values of the setup.</param>
    /// <param name="FinalStyle">The amount for which the style will be calculated based on the threshold values of the setup</param>
    procedure SetCueStyle(TableID: Integer; FieldID: Integer; Amount: Decimal; var FinalStyle: enum "Cues And KPIs Style")
    begin
        CuesAndKPIsImpl.SetCueStyle(TableID, FieldID, Amount, FinalStyle);
    end;

    /// <summary>
    /// Converts a Cues And KPIs Style enum to a style text.
    /// Enum values 0,7,8,9,10 are defined by default, if custom values are needed take a look at OnConvertStyleToStyleText event.
    /// </summary>
    /// <seealso cref="OnConvertStyleToStyleText"/>
    /// <param name="CueStyle">A Cues And KPIs Style enum from which the style text will be converted.</param>
    /// <returns>The converted style</returns>
    procedure ConvertStyleToStyleText(CueStyle: enum "Cues And KPIs Style"): Text
    begin
        exit(CuesAndKPIsImpl.ConvertStyleToStyleText(CueStyle));
    end;

    /// <summary>
    /// Inserts cue setup data. The entries inserted via this method will have no value for the userid field.
    /// </summary>
    /// <param name="TableID">The ID of the table where the cue is defined.</param>
    /// <param name="FieldNo">The ID of the field which the cue is based on.</param>
    /// <param name="LowRangeStyle">A Cues And KPIs Style enum representing the style that cues which have a value under threshold 1 will take.</param>
    /// <param name="Threshold1">The lower amount which defines which style cues get based on their value</param>
    /// <param name="MiddleRangeStyle">A Cues And KPIs Style enum representing the style that cues which have a value over threshold 1 but under threshold 2 will take.</param>
    /// <param name="Threshold2">The upper amount which defines which style cues get based on their value</param>
    /// <param name="HighRangeStyle">A Cues And KPIs Style enum representing the style that cues which have a value over threshold 2 will take.</param>
    /// <returns>True if the data was inserted successfully, false otherwise</returns>
    procedure InsertData(TableID: Integer; FieldNo: Integer; LowRangeStyle: Enum "Cues And KPIs Style"; Threshold1: Decimal;
        MiddleRangeStyle: Enum "Cues And KPIs Style"; Threshold2: Decimal; HighRangeStyle: Enum "Cues And KPIs Style"): Boolean
    begin
        exit(CuesAndKPIsImpl.InsertData(TableID, FieldNo, LowRangeStyle, Threshold1, MiddleRangeStyle, Threshold2, HighRangeStyle));
    end;

    /// <summary>
    /// Event that is called to convert from the style enum to a text value in case of extended enum values.
    /// Subscribe to this event if you want to introduce new cue styles.
    /// </summary>
    /// <param name="CueStyle">A Cues And KPIs Style enum from which the style text will be converted.</param>
    /// <param name="Result">A text vaue returned by var, which is the result of the conversion from the style enum.</param>
    /// <param name="Resolved">A boolean value that describes whether or not the custom conversion was executed.</param>
    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    internal procedure OnConvertStyleToStyleText(CueStyle: Enum "Cues And KPIs Style"; var Result: Text; var Resolved: Boolean)
    begin
    end;
}
