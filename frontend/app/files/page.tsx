'use client';

import { useState } from 'react';
import { Folder, Upload as UploadIcon, FileText, User, Shield } from 'lucide-react';
import FileUpload from '../../components/FileUpload';
import MedicalFileManager from '../../components/MedicalFileManager';

export default function FilesPage() {
  const [activeTab, setActiveTab] = useState<'upload' | 'manage'>('upload');
  const [patientId, setPatientId] = useState('');
  const [patientName, setPatientName] = useState('');
  const [showUploadForm, setShowUploadForm] = useState(false);

  const handleUploadComplete = () => {
    // Refresh the file manager when upload completes
    setActiveTab('manage');
  };

  const validatePatientInfo = () => {
    if (!patientId.trim() || !patientName.trim()) {
      alert('Please enter both Patient ID and Patient Name');
      return false;
    }
    return true;
  };

  const handleStartUpload = () => {
    if (validatePatientInfo()) {
      setShowUploadForm(true);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center">
              <Folder className="h-8 w-8 text-blue-600" />
              <div className="ml-3">
                <h1 className="text-2xl font-bold text-gray-900">Medical Files</h1>
                <p className="text-sm text-gray-600">Secure document management system</p>
              </div>
            </div>
            <div className="flex items-center text-sm text-gray-500">
              <Shield className="h-4 w-4 mr-1" />
              <span>HIPAA Compliant • AWS S3 Encrypted</span>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Tab Navigation */}
        <div className="mb-8">
          <div className="border-b border-gray-200">
            <nav className="-mb-px flex space-x-8" aria-label="Tabs">
              <button
                onClick={() => setActiveTab('upload')}
                className={`py-2 px-1 border-b-2 font-medium text-sm ${
                  activeTab === 'upload'
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <div className="flex items-center">
                  <UploadIcon className="h-5 w-5 mr-2" />
                  Upload Files
                </div>
              </button>
              <button
                onClick={() => setActiveTab('manage')}
                className={`py-2 px-1 border-b-2 font-medium text-sm ${
                  activeTab === 'manage'
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <div className="flex items-center">
                  <FileText className="h-5 w-5 mr-2" />
                  Manage Files
                </div>
              </button>
            </nav>
          </div>
        </div>

        {/* Content */}
        {activeTab === 'upload' && (
          <div className="space-y-6">
            {/* Patient Information Form */}
            {!showUploadForm && (
              <div className="bg-white rounded-lg shadow p-6">
                <h2 className="text-lg font-medium text-gray-900 mb-4">
                  Patient Information
                </h2>
                <p className="text-sm text-gray-600 mb-6">
                  Please provide patient information before uploading medical files. This information will be used to categorize and organize the files securely.
                </p>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label htmlFor="patient-id" className="block text-sm font-medium text-gray-700 mb-2">
                      Patient ID <span className="text-red-500">*</span>
                    </label>
                    <div className="relative">
                      <User className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                      <input
                        type="text"
                        id="patient-id"
                        value={patientId}
                        onChange={(e) => setPatientId(e.target.value)}
                        placeholder="Enter patient ID (e.g., P12345)"
                        className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      />
                    </div>
                  </div>
                  
                  <div>
                    <label htmlFor="patient-name" className="block text-sm font-medium text-gray-700 mb-2">
                      Patient Name <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="text"
                      id="patient-name"
                      value={patientName}
                      onChange={(e) => setPatientName(e.target.value)}
                      placeholder="Enter full patient name"
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                  </div>
                </div>

                <div className="mt-6">
                  <button
                    onClick={handleStartUpload}
                    className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition-colors"
                  >
                    Continue to File Upload
                  </button>
                </div>
              </div>
            )}

            {/* File Upload Section */}
            {showUploadForm && (
              <div className="space-y-6">
                {/* Patient Info Display */}
                <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                  <h3 className="text-sm font-medium text-blue-900 mb-2">Uploading for:</h3>
                  <div className="flex items-center text-sm text-blue-800">
                    <User className="h-4 w-4 mr-2" />
                    <span><strong>{patientName}</strong> (ID: {patientId})</span>
                  </div>
                  <button
                    onClick={() => setShowUploadForm(false)}
                    className="mt-2 text-xs text-blue-600 hover:text-blue-800 underline"
                  >
                    Change patient information
                  </button>
                </div>

                {/* Upload Guidelines */}
                <div className="bg-white rounded-lg shadow p-6">
                  <h2 className="text-lg font-medium text-gray-900 mb-4">
                    File Upload Guidelines
                  </h2>
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
                    <div className="text-center">
                      <div className="bg-blue-100 rounded-lg p-3 mb-2">
                        <FileText className="h-6 w-6 text-blue-600 mx-auto" />
                      </div>
                      <h4 className="font-medium text-sm text-gray-900">Lab Results</h4>
                      <p className="text-xs text-gray-600">Blood work, imaging, test results</p>
                    </div>
                    <div className="text-center">
                      <div className="bg-green-100 rounded-lg p-3 mb-2">
                        <FileText className="h-6 w-6 text-green-600 mx-auto" />
                      </div>
                      <h4 className="font-medium text-sm text-gray-900">Insurance</h4>
                      <p className="text-xs text-gray-600">Cards, coverage documents</p>
                    </div>
                    <div className="text-center">
                      <div className="bg-purple-100 rounded-lg p-3 mb-2">
                        <FileText className="h-6 w-6 text-purple-600 mx-auto" />
                      </div>
                      <h4 className="font-medium text-sm text-gray-900">Prescriptions</h4>
                      <p className="text-xs text-gray-600">Medication lists, pharmacy records</p>
                    </div>
                    <div className="text-center">
                      <div className="bg-amber-100 rounded-lg p-3 mb-2">
                        <FileText className="h-6 w-6 text-amber-600 mx-auto" />
                      </div>
                      <h4 className="font-medium text-sm text-gray-900">Medical Records</h4>
                      <p className="text-xs text-gray-600">History, reports, referrals</p>
                    </div>
                  </div>

                  <div className="bg-gray-50 rounded-lg p-4 mb-6">
                    <h4 className="font-medium text-sm text-gray-900 mb-2">Important Security Notes:</h4>
                    <ul className="text-xs text-gray-600 space-y-1">
                      <li>• All files are encrypted and stored securely in AWS S3</li>
                      <li>• Files are automatically categorized based on filename</li>
                      <li>• Maximum file size: 10MB per file</li>
                      <li>• Supported formats: PDF, JPG, PNG, GIF, DOC, DOCX, TXT</li>
                      <li>• Files are automatically organized by patient and category</li>
                    </ul>
                  </div>

                  <FileUpload
                    patientId={patientId}
                    patientName={patientName}
                    onUploadComplete={handleUploadComplete}
                  />
                </div>
              </div>
            )}
          </div>
        )}

        {activeTab === 'manage' && (
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-lg font-medium text-gray-900 mb-6">
              Medical File Manager
            </h2>
            <MedicalFileManager showPatientFilter={true} />
          </div>
        )}
      </div>
    </div>
  );
}