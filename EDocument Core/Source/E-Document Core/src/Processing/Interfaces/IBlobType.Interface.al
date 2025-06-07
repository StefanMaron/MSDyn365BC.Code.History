#if not CLEAN26
#pragma warning disable AS0072
#pragma warning disable AS0018
#pragma warning disable AS0004
#pragma warning disable AS0115
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Interfaces;

/// <summary>
/// Interface for Blob Type
/// </summary>
interface IBlobType
{
    ObsoleteReason = 'Use IEDocFileFormat and IStructureReceivedEDocument instead.';
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';

    /// <summary>
    /// Check if the blob type is structured
    /// </summary>
    /// <returns>True if the blob content is structured</returns>
    procedure IsStructured(): Boolean;

    /// <summary>
    /// Check if the blob type has a converter to convert its content to structured data
    /// </summary>
    /// <returns>True if the blob type has a converter</returns>
    procedure HasConverter(): Boolean;

    /// <summary>
    /// Get the converter for the blob type
    /// </summary>
    /// <returns>Converter for the blob type</returns>
    procedure GetStructuredDataConverter(): Interface IBlobToStructuredDataConverter

}
#pragma warning restore AS0115
#pragma warning restore AS0004
#pragma warning restore AS0018
#pragma warning restore AS0072
#endif