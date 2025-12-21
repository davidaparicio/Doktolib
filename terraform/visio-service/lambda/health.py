import json
import time
from datetime import datetime

def lambda_handler(event, context):
    """
    Simulates a video conference health check service.
    Returns OK status with system information.
    """

    # Extract request information
    http_method = event.get('httpMethod', 'GET')
    path = event.get('path', '/')

    # Health check endpoint
    if path == '/health' or path == '/api/health':
        response_body = {
            'status': 'OK',
            'service': 'visio-conference',
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'version': '1.0.0',
            'region': context.invoked_function_arn.split(':')[3],
            'uptime': 'healthy',
            'checks': {
                'api': 'operational',
                'video_streaming': 'operational',
                'audio_streaming': 'operational',
                'signaling_server': 'operational',
                'turn_servers': 'operational'
            }
        }

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Cache-Control': 'no-cache, no-store, must-revalidate'
            },
            'body': json.dumps(response_body)
        }

    # Status endpoint (alternative)
    elif path == '/status' or path == '/api/status':
        response_body = {
            'status': 'OK',
            'service': 'visio-conference',
            'message': 'Video conference service is operational',
            'timestamp': datetime.utcnow().isoformat() + 'Z'
        }

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps(response_body)
        }

    # Root endpoint
    elif path == '/' or path == '/api':
        response_body = {
            'service': 'Doktolib Video Conference Service',
            'version': '1.0.0',
            'endpoints': {
                'health': '/health',
                'status': '/status'
            },
            'timestamp': datetime.utcnow().isoformat() + 'Z'
        }

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(response_body)
        }

    # Handle OPTIONS for CORS preflight
    elif http_method == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': ''
        }

    # 404 for unknown paths
    else:
        return {
            'statusCode': 404,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Not Found',
                'message': f'Path {path} not found',
                'available_endpoints': ['/health', '/status', '/']
            })
        }
