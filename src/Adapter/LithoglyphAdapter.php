<?php
// SPDX-License-Identifier: PMPL-1.0-or-later

declare(strict_types=1);

namespace App\Adapter;

use League\Flysystem\FilesystemAdapter;
use League\Flysystem\Config;
use League\Flysystem\FileAttributes;
use League\Flysystem\DirectoryAttributes;

/**
 * Lithoglyph Flysystem Adapter
 *
 * Bridges Pimcore's DAM to Lithoglyph immutable storage.
 * All "lens-based" assets are engraved into Lithoglyph,
 * providing cryptographic IP protection.
 *
 * @author Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>
 */
class LithoglyphAdapter implements FilesystemAdapter
{
    private string $apiUrl;
    private ?string $apiKey;

    public function __construct(string $apiUrl, ?string $apiKey = null)
    {
        $this->apiUrl = rtrim($apiUrl, '/');
        $this->apiKey = $apiKey;
    }

    /**
     * Check if a file exists in Lithoglyph.
     */
    public function fileExists(string $path): bool
    {
        $response = $this->apiRequest('HEAD', "/assets/{$path}");
        return $response['status'] === 200;
    }

    /**
     * Check if a directory exists in Lithoglyph.
     */
    public function directoryExists(string $path): bool
    {
        $response = $this->apiRequest('HEAD', "/directories/{$path}");
        return $response['status'] === 200;
    }

    /**
     * Write a file to Lithoglyph (engraving).
     * Returns metadata including cryptographic hash.
     */
    public function write(string $path, string $contents, Config $config): void
    {
        $response = $this->apiRequest('POST', '/assets', [
            'path' => $path,
            'content' => base64_encode($contents),
            'metadata' => $config->get('metadata', [])
        ]);

        if ($response['status'] !== 201) {
            throw new \RuntimeException("Failed to write to Lithoglyph: {$response['error']}");
        }
    }

    /**
     * Write a stream to Lithoglyph.
     */
    public function writeStream(string $path, $contents, Config $config): void
    {
        $data = stream_get_contents($contents);
        $this->write($path, $data, $config);
    }

    /**
     * Read a file from Lithoglyph.
     */
    public function read(string $path): string
    {
        $response = $this->apiRequest('GET', "/assets/{$path}");

        if ($response['status'] !== 200) {
            throw new \RuntimeException("Failed to read from Lithoglyph: {$response['error']}");
        }

        return base64_decode($response['data']['content']);
    }

    /**
     * Read a file as a stream from Lithoglyph.
     */
    public function readStream(string $path)
    {
        $content = $this->read($path);
        $stream = fopen('php://temp', 'r+');
        fwrite($stream, $content);
        rewind($stream);
        return $stream;
    }

    /**
     * Delete a file from Lithoglyph.
     * Note: In immutable mode, this may only mark as deleted.
     */
    public function delete(string $path): void
    {
        $response = $this->apiRequest('DELETE', "/assets/{$path}");

        if ($response['status'] !== 204 && $response['status'] !== 200) {
            throw new \RuntimeException("Failed to delete from Lithoglyph: {$response['error']}");
        }
    }

    /**
     * Delete a directory from Lithoglyph.
     */
    public function deleteDirectory(string $path): void
    {
        $response = $this->apiRequest('DELETE', "/directories/{$path}");

        if ($response['status'] !== 204 && $response['status'] !== 200) {
            throw new \RuntimeException("Failed to delete directory from Lithoglyph: {$response['error']}");
        }
    }

    /**
     * Create a directory in Lithoglyph.
     */
    public function createDirectory(string $path, Config $config): void
    {
        $response = $this->apiRequest('POST', '/directories', [
            'path' => $path
        ]);

        if ($response['status'] !== 201) {
            throw new \RuntimeException("Failed to create directory in Lithoglyph: {$response['error']}");
        }
    }

    /**
     * Set visibility (permissions) for a file.
     */
    public function setVisibility(string $path, string $visibility): void
    {
        $response = $this->apiRequest('PATCH', "/assets/{$path}", [
            'visibility' => $visibility
        ]);

        if ($response['status'] !== 200) {
            throw new \RuntimeException("Failed to set visibility in Lithoglyph: {$response['error']}");
        }
    }

    /**
     * Get file visibility.
     */
    public function visibility(string $path): FileAttributes
    {
        $response = $this->apiRequest('GET', "/assets/{$path}/metadata");

        return new FileAttributes(
            $path,
            null,
            $response['data']['visibility'] ?? 'private'
        );
    }

    /**
     * Get file metadata.
     */
    public function mimeType(string $path): FileAttributes
    {
        $response = $this->apiRequest('GET', "/assets/{$path}/metadata");

        return new FileAttributes(
            $path,
            null,
            null,
            null,
            $response['data']['mime_type'] ?? 'application/octet-stream'
        );
    }

    /**
     * Get last modified timestamp.
     */
    public function lastModified(string $path): FileAttributes
    {
        $response = $this->apiRequest('GET', "/assets/{$path}/metadata");

        return new FileAttributes(
            $path,
            null,
            null,
            $response['data']['last_modified'] ?? time()
        );
    }

    /**
     * Get file size.
     */
    public function fileSize(string $path): FileAttributes
    {
        $response = $this->apiRequest('GET', "/assets/{$path}/metadata");

        return new FileAttributes(
            $path,
            $response['data']['size'] ?? 0
        );
    }

    /**
     * List contents of a directory.
     */
    public function listContents(string $path, bool $deep): iterable
    {
        $response = $this->apiRequest('GET', "/directories/{$path}", [
            'recursive' => $deep ? 'true' : 'false'
        ]);

        if ($response['status'] !== 200) {
            return [];
        }

        foreach ($response['data']['items'] as $item) {
            if ($item['type'] === 'file') {
                yield new FileAttributes(
                    $item['path'],
                    $item['size'] ?? null,
                    $item['visibility'] ?? null,
                    $item['last_modified'] ?? null,
                    $item['mime_type'] ?? null
                );
            } else {
                yield new DirectoryAttributes($item['path']);
            }
        }
    }

    /**
     * Move a file in Lithoglyph.
     */
    public function move(string $source, string $destination, Config $config): void
    {
        $response = $this->apiRequest('POST', "/assets/{$source}/move", [
            'destination' => $destination
        ]);

        if ($response['status'] !== 200) {
            throw new \RuntimeException("Failed to move file in Lithoglyph: {$response['error']}");
        }
    }

    /**
     * Copy a file in Lithoglyph.
     */
    public function copy(string $source, string $destination, Config $config): void
    {
        $response = $this->apiRequest('POST', "/assets/{$source}/copy", [
            'destination' => $destination
        ]);

        if ($response['status'] !== 201) {
            throw new \RuntimeException("Failed to copy file in Lithoglyph: {$response['error']}");
        }
    }

    /**
     * Make an API request to Lithoglyph.
     *
     * @return array{status: int, data?: array, error?: string}
     */
    private function apiRequest(string $method, string $endpoint, array $data = []): array
    {
        $url = $this->apiUrl . $endpoint;

        $ch = curl_init();

        curl_setopt_array($ch, [
            CURLOPT_URL => $url,
            CURLOPT_CUSTOMREQUEST => $method,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => array_filter([
                'Content-Type: application/json',
                $this->apiKey ? "Authorization: Bearer {$this->apiKey}" : null
            ]),
            CURLOPT_POSTFIELDS => !empty($data) ? json_encode($data) : null
        ]);

        $response = curl_exec($ch);
        $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);

        curl_close($ch);

        if ($error) {
            return ['status' => 0, 'error' => $error];
        }

        $decoded = json_decode($response, true);

        return [
            'status' => $status,
            'data' => $decoded ?? [],
            'error' => $decoded['error'] ?? null
        ];
    }
}
